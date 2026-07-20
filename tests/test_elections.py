import pandas as pd

from municipal_dw.sources.elections import ElectionSource


def test_official_election_xlsx_is_aggregated_without_double_counting_voters() -> None:
    source = pd.DataFrame(
        [
            {
                " Valdistriktskod": " 018001",
                " Parti": " Moderaterna",
                " Röster": "10",
                " Röstberättigade": "100",
            },
            {
                " Valdistriktskod": " 018001",
                " Parti": " blanka röster",
                " Röster": "2",
                " Röstberättigade": "100",
            },
            {
                " Valdistriktskod": " 018002",
                " Parti": " Moderaterna",
                " Röster": "20",
                " Röstberättigade": "80",
            },
            {
                " Valdistriktskod": " 018002",
                " Parti": " Vänsterpartiet",
                " Röster": "15",
                " Röstberättigade": "80",
            },
            {
                " Valdistriktskod": " 018001",
                " Parti": " Summa giltiga röster",
                " Röster": "10",
                " Röstberättigade": "100",
            },
            {
                " Valdistriktskod": " 018002",
                " Parti": " Summa giltiga röster",
                " Röster": "35",
                " Röstberättigade": "80",
            },
            {
                " Valdistriktskod": " 018002",
                " Parti": " Valdeltagande",
                " Röster": "40",
                " Röstberättigade": "80",
            },
        ]
    )
    rows = ElectionSource._from_official_xlsx(source, 2022)
    by_party = {row.party_code: row for row in rows}
    assert by_party["M"].party_votes == 30
    assert by_party["M"].valid_votes == 45
    assert by_party["M"].eligible_voters == 180
    assert "V" in by_party
    assert len(rows) == 2
