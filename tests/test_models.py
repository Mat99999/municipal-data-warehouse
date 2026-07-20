from decimal import Decimal

import pytest
from pydantic import ValidationError

from municipal_dw.models import ElectionRow, KpiRow, Municipality, PopulationRow


def test_municipality_requires_four_digit_code() -> None:
    with pytest.raises(ValidationError):
        Municipality(
            municipality_code="180",
            municipality_name="Stockholm",
            region_code="01",
            region_name="Stockholms län",
        )


@pytest.mark.parametrize(("raw", "expected"), [("1", "male"), ("Kvinnor", "female")])
def test_population_normalizes_scb_sex(raw: str, expected: str) -> None:
    row = PopulationRow(municipality_code="0180", year=2024, sex=raw, age=42, population_count=100)
    assert row.sex == expected


def test_kpi_decimal_is_preserved() -> None:
    row = KpiRow(
        municipality_code="0180",
        year=2024,
        kpi_id="N20043",
        kpi_name="Cost",
        unit="SEK",
        category="Eldercare",
        value="123.45",
    )
    assert row.value == Decimal("123.45")


def test_election_rejects_negative_votes() -> None:
    with pytest.raises(ValidationError):
        ElectionRow(
            municipality_code="0180",
            election_year=2022,
            party_code="s",
            party_name="Socialdemokraterna",
            eligible_voters=100,
            valid_votes=90,
            party_votes=-1,
            seats=1,
        )
