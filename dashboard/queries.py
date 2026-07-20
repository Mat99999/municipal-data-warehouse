from __future__ import annotations

import os
from typing import Any

import pandas as pd
import streamlit as st
from sqlalchemy import Engine, create_engine, text


@st.cache_resource
def database_engine() -> Engine:
    url = os.environ.get(
        "DASHBOARD_DATABASE_URL",
        "postgresql+psycopg://dashboard_reader:dashboard_reader_password@localhost:5432/municipal_dw",
    )
    return create_engine(url, pool_pre_ping=True)


@st.cache_data(ttl=300)
def query(sql: str, params: dict[str, Any] | None = None) -> pd.DataFrame:
    with database_engine().connect() as connection:
        return pd.read_sql(text(sql), connection, params=params or {})


def municipalities() -> pd.DataFrame:
    return query(
        """select distinct municipality_code, municipality_name
        from analytics.mv_municipality_scorecard order by municipality_name"""
    )


def scorecard(code: str) -> pd.DataFrame:
    return query(
        """select * from analytics.mv_municipality_scorecard
        where municipality_code = :code order by year""",
        {"code": code},
    )


def peers(year: int) -> pd.DataFrame:
    return query(
        """select municipality_name, population_growth_rate,
        eldercare_cost_per_resident, eldercare_satisfaction_pct
        from analytics.mart_peer_benchmark where year = :year
        order by population_growth_rate desc nulls last""",
        {"year": year},
    )


def demographics(code: str, year: int) -> pd.DataFrame:
    return query(
        """select age_band, sex, population
        from analytics.mart_demographics
        where municipality_code = :code and year = :year
        order by age_band, sex""",
        {"code": code, "year": year},
    )


def elections(code: str) -> pd.DataFrame:
    return query(
        """select year_key as election_year, party_name, vote_share, seats
        from analytics.mart_election_change
        where municipality_code = :code
        order by year_key, vote_share desc""",
        {"code": code},
    )


def freshness() -> pd.DataFrame:
    return query("select * from analytics.mart_source_freshness order by source_name")


def quality_checks() -> pd.DataFrame:
    return query(
        """select check_name, violation_count, expectation,
        case when violation_count = 0 then 'PASS' else 'FAIL' end as status
        from analytics.mart_data_quality order by check_name"""
    )
