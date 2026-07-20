from __future__ import annotations

from decimal import Decimal
from typing import Any

from municipal_dw.models import KpiRow, Municipality
from municipal_dw.sources.base import HttpSource

COUNTIES = {
    "01": "Stockholms län",
    "03": "Uppsala län",
    "04": "Södermanlands län",
    "05": "Östergötlands län",
    "06": "Jönköpings län",
    "07": "Kronobergs län",
    "08": "Kalmar län",
    "09": "Gotlands län",
    "10": "Blekinge län",
    "12": "Skåne län",
    "13": "Hallands län",
    "14": "Västra Götalands län",
    "17": "Värmlands län",
    "18": "Örebro län",
    "19": "Västmanlands län",
    "20": "Dalarnas län",
    "21": "Gävleborgs län",
    "22": "Västernorrlands län",
    "23": "Jämtlands län",
    "24": "Västerbottens län",
    "25": "Norrbottens län",
}


class KoladaSource(HttpSource):
    def municipalities(self) -> list[Municipality]:
        payload = self.get("/municipality", params={"page_size": 1000}).json()
        items = _items(payload)
        return [
            Municipality(
                municipality_code=str(item["id"]),
                municipality_name=str(item["title"]),
                region_code=str(item.get("county", item["id"][:2]))[:2],
                region_name=str(
                    item.get("county_title", COUNTIES.get(str(item["id"])[:2], "Unknown region"))
                ),
            )
            for item in items
            if _is_municipality_code(str(item.get("id", "")))
        ]

    def fetch(self, kpi_ids: list[str], years: list[str]) -> list[KpiRow]:
        metadata: dict[str, dict[str, Any]] = {}
        for kpi_id in kpi_ids:
            item = _items(self.get(f"/kpi/{kpi_id}").json())[0]
            metadata[kpi_id] = item

        rows: list[KpiRow] = []
        for kpi_id in kpi_ids:
            for year in years:
                payload = self.get(
                    f"/data/kpi/{kpi_id}/year/{year}", params={"page_size": 1000}
                ).json()
                for item in _items(payload):
                    municipality_code = str(
                        item.get("municipality", item.get("municipality_id", ""))
                    )
                    if isinstance(item.get("municipality"), dict):
                        municipality_code = str(item["municipality"].get("id", ""))
                    if not _is_municipality_code(municipality_code):
                        continue
                    for sex, raw_value in _values(item):
                        if raw_value is None:
                            continue
                        meta = metadata[kpi_id]
                        rows.append(
                            KpiRow(
                                municipality_code=municipality_code,
                                year=int(item.get("period", item.get("year", year))),
                                kpi_id=kpi_id,
                                kpi_name=str(meta.get("title", kpi_id)),
                                unit=_unit(str(meta.get("title", ""))),
                                category=str(meta.get("operating_area", "Municipal performance")),
                                sex=sex,
                                value=Decimal(str(raw_value)),
                            )
                        )
        return rows


def _items(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return payload
    for key in ("values", "data", "items", "results"):
        value = payload.get(key) if isinstance(payload, dict) else None
        if isinstance(value, list):
            return value
    if isinstance(payload, dict) and "id" in payload:
        return [payload]
    raise ValueError("Unexpected Kolada response contract")


def _values(item: dict[str, Any]) -> list[tuple[str, Any]]:
    values = item.get("values", item.get("value"))
    if isinstance(values, list):
        result = []
        for value in values:
            if isinstance(value, dict):
                gender = {"T": "not_applicable", "M": "male", "K": "female"}.get(
                    str(value.get("gender", "T")).upper(), "not_applicable"
                )
                result.append((gender, value.get("value")))
            else:
                result.append(("not_applicable", value))
        return result
    if isinstance(values, dict):
        return [(str(key).lower(), value) for key, value in values.items()]
    return [("not_applicable", values)]


def _unit(title: str) -> str:
    lowered = title.lower()
    if "(%)" in title or "andel" in lowered or "skattesats" in lowered:
        return "percent"
    if "kr/inv" in lowered:
        return "SEK per resident"
    return "value"


def _is_municipality_code(code: str) -> bool:
    """Exclude national and region aggregates exposed by Kolada's endpoint."""
    return len(code) == 4 and code.isdigit() and code[:2] in COUNTIES
