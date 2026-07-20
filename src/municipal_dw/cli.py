from __future__ import annotations

import json
from typing import Annotated

import typer

from municipal_dw.config import Settings
from municipal_dw.ingest import run
from municipal_dw.logging import configure_logging

app = typer.Typer(no_args_is_help=True, help="Municipal warehouse ingestion and QA CLI")


@app.command()
def ingest(
    mode: Annotated[
        str, typer.Option(help="fixture for deterministic demo, live for APIs")
    ] = "fixture",
) -> None:
    settings = Settings()
    configure_logging(settings.log_level)
    counts = run(settings, mode)
    typer.echo(json.dumps(counts, sort_keys=True))


if __name__ == "__main__":
    app()
