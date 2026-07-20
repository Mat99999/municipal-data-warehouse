from __future__ import annotations

from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator


class StrictRow(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class Municipality(StrictRow):
    municipality_code: str = Field(pattern=r"^\d{4}$")
    municipality_name: str
    region_code: str = Field(pattern=r"^\d{2}$")
    region_name: str


class PopulationRow(StrictRow):
    municipality_code: str = Field(pattern=r"^\d{4}$")
    year: int = Field(ge=1968, le=2100)
    sex: str
    age: int = Field(ge=0, le=110)
    population_count: int = Field(ge=0)

    @field_validator("sex")
    @classmethod
    def valid_sex(cls, value: str) -> str:
        normalized = value.lower()
        aliases = {"1": "male", "2": "female", "män": "male", "kvinnor": "female"}
        normalized = aliases.get(normalized, normalized)
        if normalized not in {"male", "female"}:
            raise ValueError("sex must resolve to male or female")
        return normalized


class KpiRow(StrictRow):
    municipality_code: str = Field(pattern=r"^\d{4}$")
    year: int = Field(ge=1900, le=2100)
    kpi_id: str = Field(pattern=r"^[NU]\d{5}$")
    kpi_name: str
    unit: str
    category: str
    sex: str = "not_applicable"
    value: Decimal


class ElectionRow(StrictRow):
    municipality_code: str = Field(pattern=r"^\d{4}$")
    election_year: int = Field(ge=1900, le=2100)
    party_code: str
    party_name: str
    eligible_voters: int = Field(ge=0)
    valid_votes: int = Field(ge=0)
    party_votes: int = Field(ge=0)
    seats: int | None = Field(default=None, ge=0)

    @field_validator("party_code")
    @classmethod
    def uppercase_party(cls, value: str) -> str:
        return value.upper()
