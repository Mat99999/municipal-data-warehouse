from municipal_dw.sources.kolada import _is_municipality_code


def test_kolada_geography_filter_keeps_only_municipalities() -> None:
    assert _is_municipality_code("0180")
    assert _is_municipality_code("1480")
    assert not _is_municipality_code("0000")  # national aggregate
    assert not _is_municipality_code("0001")  # regional aggregate
    assert not _is_municipality_code("01")
