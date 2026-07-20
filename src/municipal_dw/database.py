from __future__ import annotations

import hashlib
import json
import uuid
from collections.abc import Iterable, Mapping
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

from sqlalchemy import Connection, Engine, create_engine, text


def engine_for(url: str) -> Engine:
    return create_engine(url, pool_pre_ping=True)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def start_batch(engine: Engine, mode: str, source_manifest: Mapping[str, Any]) -> uuid.UUID:
    batch_id = uuid.uuid4()
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                INSERT INTO raw.ingestion_batch
                    (batch_id, mode, started_at, status, source_manifest)
                VALUES (:batch_id, :mode, :started_at, 'running', CAST(:manifest AS jsonb))
                """
            ),
            {
                "batch_id": batch_id,
                "mode": mode,
                "started_at": datetime.now(UTC),
                "manifest": json.dumps(source_manifest),
            },
        )
    return batch_id


def finish_batch(
    engine: Engine, batch_id: uuid.UUID, status: str, row_counts: Mapping[str, int]
) -> None:
    with engine.begin() as connection:
        connection.execute(
            text(
                """
                UPDATE raw.ingestion_batch
                SET completed_at = :completed_at,
                    status = :status,
                    row_counts = CAST(:row_counts AS jsonb)
                WHERE batch_id = :batch_id
                """
            ),
            {
                "batch_id": batch_id,
                "completed_at": datetime.now(UTC),
                "status": status,
                "row_counts": json.dumps(row_counts),
            },
        )


def replace_source_rows(
    connection: Connection,
    table: str,
    source_name: str,
    batch_id: uuid.UUID,
    rows: Iterable[Mapping[str, Any]],
) -> int:
    payloads = [dict(row, batch_id=batch_id, source_name=source_name) for row in rows]
    connection.execute(text(f"TRUNCATE TABLE raw.{table}"))
    if payloads:
        columns = list(payloads[0])
        column_sql = ", ".join(columns)
        value_sql = ", ".join(f":{column}" for column in columns)
        connection.execute(
            text(f"INSERT INTO raw.{table} ({column_sql}) VALUES ({value_sql})"), payloads
        )
    return len(payloads)
