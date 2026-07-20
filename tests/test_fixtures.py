from municipal_dw.sources.fixtures import (
    election_rows,
    kpi_rows,
    municipality_rows,
    population_rows,
)


def test_committed_fixture_contract(settings) -> None:  # type: ignore[no-untyped-def]
    assert len(municipality_rows(settings.fixture_dir)) == 3
    assert len(population_rows(settings.fixture_dir)) == 72
    assert len(kpi_rows(settings.fixture_dir)) == 27
    assert len(election_rows(settings.fixture_dir)) == 18
