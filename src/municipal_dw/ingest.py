from __future__ import annotations

from collections.abc import Iterable
from typing import Any

import structlog
from pydantic import BaseModel

from municipal_dw.config import Settings
from municipal_dw.database import (
    engine_for,
    finish_batch,
    replace_source_rows,
    sha256_file,
    start_batch,
)
from municipal_dw.sources import fixtures
from municipal_dw.sources.elections import ElectionSource
from municipal_dw.sources.kolada import KoladaSource
from municipal_dw.sources.scb import ScbSource

logger = structlog.get_logger()


def _records(rows: Iterable[BaseModel]) -> list[dict[str, Any]]:
    return [row.model_dump(mode="python") for row in rows]


def run(settings: Settings, mode: str) -> dict[str, int]:
    if mode not in {"fixture", "live"}:
        raise ValueError("mode must be fixture or live")
    engine = engine_for(settings.database_url)
    manifest = {
        "scb": {"api": "v2", "table": settings.scb_table_id},
        "kolada": {"api": "v3", "kpis": settings.csv_values(settings.kolada_kpi_ids)},
        "elections": {"url": settings.election_source_url if mode == "live" else "fixture"},
    }
    if mode == "fixture":
        manifest["fixtures"] = {
            path.name: sha256_file(path) for path in sorted(settings.fixture_dir.glob("*.csv"))
        }
    batch_id = start_batch(engine, mode, manifest)
    counts: dict[str, int] = {}
    try:
        if mode == "fixture":
            municipalities = fixtures.municipality_rows(settings.fixture_dir)
            population = fixtures.population_rows(settings.fixture_dir)
            kpis = fixtures.kpi_rows(settings.fixture_dir)
            elections = fixtures.election_rows(settings.fixture_dir)
        else:
            kolada = KoladaSource(settings.kolada_base_url, settings.http_timeout_seconds)
            municipalities = kolada.municipalities()
            population = ScbSource(
                settings.scb_base_url, settings.scb_table_id, settings.http_timeout_seconds
            ).fetch(settings.csv_values(settings.scb_years))
            kpis = kolada.fetch(
                settings.csv_values(settings.kolada_kpi_ids),
                settings.csv_values(settings.kolada_years),
            )
            elections = ElectionSource("https://www.val.se", settings.http_timeout_seconds).fetch(
                settings.election_source_url, settings.election_year
            )

        # Publish a complete source snapshot atomically: a late-source failure cannot
        # leave raw tables representing different ingestion runs.
        with engine.begin() as connection:
            for table, source, rows in (
                ("municipality", "Kolada", municipalities),
                ("population", "SCB", population),
                ("municipal_kpi", "Kolada", kpis),
                ("election_result", "Valmyndigheten", elections),
            ):
                counts[table] = replace_source_rows(
                    connection, table, source, batch_id, _records(rows)
                )
                logger.info(
                    "source_loaded", table=table, rows=counts[table], batch_id=str(batch_id)
                )
        finish_batch(engine, batch_id, "succeeded", counts)
        return counts
    except Exception:
        finish_batch(engine, batch_id, "failed", counts)
        logger.exception("ingestion_failed", batch_id=str(batch_id))
        raise
