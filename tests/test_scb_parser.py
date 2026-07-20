from municipal_dw.sources.scb import ScbSource


def test_jsonstat_parser_is_dimension_order_independent() -> None:
    payload = {
        "id": ["Tid", "Region", "Kon", "Alder"],
        "size": [1, 1, 2, 1],
        "dimension": {
            "Tid": {"category": {"index": {"2024": 0}}},
            "Region": {"category": {"index": {"0180": 0}}},
            "Kon": {"category": {"index": {"1": 0, "2": 1}}},
            "Alder": {"category": {"index": {"85": 0}}},
        },
        "value": [100, 120],
    }
    rows = ScbSource._parse_jsonstat(payload)
    assert [(row.sex, row.population_count) for row in rows] == [("male", 100), ("female", 120)]
