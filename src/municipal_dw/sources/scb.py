from __future__ import annotations

from itertools import product
from typing import Any

from municipal_dw.models import PopulationRow
from municipal_dw.sources.base import HttpSource


class ScbSource(HttpSource):
    """PxWeb API v2 adapter.

    The response parser follows JSON-stat2 and is deliberately independent of
    dimension order. Requests are split by year to remain below API cell limits.
    """

    def __init__(self, base_url: str, table_id: str, timeout: float = 60.0) -> None:
        super().__init__(base_url, timeout)
        self.table_id = table_id

    def fetch(self, years: list[str]) -> list[PopulationRow]:
        rows: list[PopulationRow] = []
        ages = ",".join([*(str(age) for age in range(100)), "100+"])
        for year in years:
            params = {
                "lang": "sv",
                "valuecodes[Region]": "*",
                "valuecodes[Alder]": ages,
                "valuecodes[Kon]": "1,2",
                "valuecodes[ContentsCode]": "BE0101N1",
                "valuecodes[Tid]": year,
                "outputFormat": "json-stat2",
            }
            response = self.get(f"/tables/{self.table_id}/data", params=params)
            rows.extend(self._parse_jsonstat(response.json()))
        return rows

    @staticmethod
    def _parse_jsonstat(dataset: dict[str, Any]) -> list[PopulationRow]:
        dimension_ids = dataset.get("id", [])
        dimensions = dataset.get("dimension", {})
        sizes = dataset.get("size", [])
        values = dataset.get("value", [])
        codes: list[list[str]] = []
        labels: list[dict[str, str]] = []
        for dimension_id in dimension_ids:
            category = dimensions[dimension_id]["category"]
            index = category.get("index", {})
            ordered = (
                list(index)
                if isinstance(index, list)
                else [key for key, _ in sorted(index.items(), key=lambda pair: pair[1])]
            )
            codes.append(ordered)
            labels.append(category.get("label", {}))

        result: list[PopulationRow] = []
        for offset, coordinates in enumerate(product(*(range(size) for size in sizes))):
            value = values[offset] if isinstance(values, list) else values.get(str(offset))
            if value is None:
                continue
            row = {dimension_ids[i]: codes[i][position] for i, position in enumerate(coordinates)}
            municipality_code = str(row.get("Region", ""))
            if len(municipality_code) != 4 or not municipality_code.isdigit():
                continue
            raw_age = str(row.get("Alder", "0"))
            if raw_age == "tot":
                continue
            age = 100 if raw_age in {"100+", "100-w"} else int(raw_age)
            result.append(
                PopulationRow(
                    municipality_code=municipality_code,
                    year=int(row["Tid"]),
                    sex=str(row["Kon"]),
                    age=age,
                    population_count=int(value),
                )
            )
        return result
