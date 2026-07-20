from __future__ import annotations

from collections.abc import Iterable
from pathlib import Path

import polars as pl
from pydantic import BaseModel

from municipal_dw.models import ElectionRow, KpiRow, Municipality, PopulationRow


def _read[T: BaseModel](path: Path, model: type[T]) -> list[T]:
    frame = pl.read_csv(path, infer_schema=False, null_values=["", "NA", ".."]).drop_nulls()
    return [model.model_validate(row) for row in frame.to_dicts()]


def municipality_rows(directory: Path) -> list[Municipality]:
    return _read(directory / "municipalities.csv", Municipality)


def population_rows(directory: Path) -> list[PopulationRow]:
    return _read(directory / "population.csv", PopulationRow)


def kpi_rows(directory: Path) -> list[KpiRow]:
    return _read(directory / "kolada_kpi.csv", KpiRow)


def election_rows(directory: Path) -> list[ElectionRow]:
    return _read(directory / "elections.csv", ElectionRow)


def dump(rows: Iterable[BaseModel]) -> list[dict[str, object]]:
    return [row.model_dump(mode="python") for row in rows]
