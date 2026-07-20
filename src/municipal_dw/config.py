from __future__ import annotations

from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration. Secrets are read from the environment only."""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = (
        "postgresql+psycopg://warehouse_admin:warehouse_dev_password@localhost:5432/municipal_dw"
    )
    data_dir: Path = Path("data")
    log_level: str = "INFO"
    scb_base_url: str = "https://statistikdatabasen.scb.se/api/v2"
    scb_table_id: str = "TAB638"
    scb_years: str = "2022,2023,2024"
    kolada_base_url: str = "https://api.kolada.se/v3"
    kolada_kpi_ids: str = "N20043,N00533,N00901"
    kolada_years: str = "2022,2023,2024"
    election_source_url: str = "https://www.val.se/download/18.162047b519a91d0533118f4e/1764337121617/roster-per-distrikt-slutligt-antal-roster-inklusive-totalt-valdeltagande-kommunval-2022.xlsx"
    election_year: int = 2022
    http_timeout_seconds: float = Field(default=60.0, gt=0)

    @property
    def fixture_dir(self) -> Path:
        return self.data_dir / "fixtures"

    @property
    def live_dir(self) -> Path:
        return self.data_dir / "live"

    @staticmethod
    def csv_values(value: str) -> list[str]:
        return [item.strip() for item in value.split(",") if item.strip()]
