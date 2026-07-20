from __future__ import annotations

import hashlib
import io
import re
from typing import Any, cast

import pandas as pd
import polars as pl

from municipal_dw.models import ElectionRow
from municipal_dw.sources.base import HttpSource

MAJOR_PARTIES = {
    "Arbetarepartiet-Socialdemokraterna": "S",
    "Moderaterna": "M",
    "Sverigedemokraterna": "SD",
    "Vänsterpartiet": "V",
    "Centerpartiet": "C",
    "Kristdemokraterna": "KD",
    "Liberalerna (tidigare Folkpartiet)": "L",
    "Miljöpartiet de gröna": "MP",
}
NON_PARTY_ROWS = {
    "blanka röster",
    "ogiltiga röster",
    "övriga ogiltiga",
    "övriga ogiltiga röster",
    "summa giltiga röster",
    "valdeltagande",
}


class ElectionSource(HttpSource):
    """Valmyndigheten adapter for normalized CSV or official district XLSX."""

    def fetch(self, source_url: str, election_year: int) -> list[ElectionRow]:
        response = self.get(source_url)
        if source_url.lower().endswith(".xlsx"):
            pandas_frame = pd.read_excel(
                io.BytesIO(response.content), sheet_name="roster_KF", dtype=str, engine="openpyxl"
            )
            return self._from_official_xlsx(pandas_frame, election_year)
        polars_frame = pl.read_csv(
            io.BytesIO(response.content), separator=";", infer_schema_length=10000
        )
        aliases = {
            "kommunkod": "municipality_code",
            "valår": "election_year",
            "partikod": "party_code",
            "partinamn": "party_name",
            "röstberättigade": "eligible_voters",
            "giltiga_röster": "valid_votes",
            "partiröster": "party_votes",
            "mandat": "seats",
        }
        polars_frame = polars_frame.rename(
            {name: aliases.get(name.lower(), name.lower()) for name in polars_frame.columns}
        )
        return [ElectionRow.model_validate(row) for row in polars_frame.to_dicts()]

    @staticmethod
    def _from_official_xlsx(frame: pd.DataFrame, election_year: int) -> list[ElectionRow]:
        frame = frame.rename(columns=lambda column: str(column).strip())
        required = {"Valdistriktskod", "Parti", "Röster", "Röstberättigade"}
        if not required.issubset(frame.columns):
            raise ValueError(
                f"Valmyndigheten XLSX is missing columns: {required - set(frame.columns)}"
            )

        working = frame[list(required)].copy()
        working["Valdistriktskod"] = working["Valdistriktskod"].str.strip()
        working["municipality_code"] = working["Valdistriktskod"].str[:4]
        working["Parti"] = working["Parti"].str.strip()
        working["Röster"] = pd.to_numeric(working["Röster"], errors="coerce").fillna(0).astype(int)
        working["Röstberättigade"] = (
            pd.to_numeric(working["Röstberättigade"], errors="coerce").fillna(0).astype(int)
        )
        working = working[working["municipality_code"].str.fullmatch(r"\d{4}")]

        eligible = (
            working.groupby(["municipality_code", "Valdistriktskod"], as_index=False)[
                "Röstberättigade"
            ]
            .max()
            .groupby("municipality_code")["Röstberättigade"]
            .sum()
        )
        labels = working["Parti"].str.lower()
        parties = working[~labels.isin(NON_PARTY_ROWS)].copy()
        valid_totals = parties.groupby("municipality_code")["Röster"].sum()
        published_valid_totals = (
            working[labels == "summa giltiga röster"].groupby("municipality_code")["Röster"].sum()
        )
        valid_totals.update(published_valid_totals)
        party_totals = cast(
            pd.DataFrame,
            parties.groupby(["municipality_code", "Parti"], as_index=False)["Röster"].sum(),
        )

        rows: list[ElectionRow] = []
        records = cast(list[dict[str, Any]], party_totals.to_dict(orient="records"))
        for record in records:
            code = str(record["municipality_code"])
            party_name = str(record["Parti"])
            rows.append(
                ElectionRow(
                    municipality_code=code,
                    election_year=election_year,
                    party_code=_party_code(party_name),
                    party_name=party_name,
                    eligible_voters=int(eligible.get(code, 0)),
                    valid_votes=int(valid_totals.get(code, 0)),
                    party_votes=int(record["Röster"]),
                    # The district-vote workbook contains votes, not mandates.
                    seats=None,
                )
            )
        return rows


def _party_code(name: str) -> str:
    if name in MAJOR_PARTIES:
        return MAJOR_PARTIES[name]
    slug = re.sub(r"[^A-Z0-9]+", "_", name.upper()).strip("_")[:18]
    digest = hashlib.sha1(name.encode("utf-8"), usedforsecurity=False).hexdigest()[:6]
    return f"{slug}_{digest}" if slug else f"PARTY_{digest}"
