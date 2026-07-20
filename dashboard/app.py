from __future__ import annotations

import pandas as pd
import plotly.express as px
import streamlit as st
from queries import (
    demographics,
    elections,
    freshness,
    municipalities,
    peers,
    quality_checks,
    scorecard,
)

st.set_page_config(page_title="Swedish Municipal Data", page_icon="🏛️", layout="wide")
st.title("Swedish Municipal Intelligence")
st.caption("Source-backed municipal trends from SCB, Kolada, and Valmyndigheten")

try:
    options = municipalities()
except Exception as exc:
    st.error("The analytics warehouse is unavailable. Run `make demo` before opening the app.")
    st.exception(exc)
    st.stop()

if options.empty:
    st.warning("No municipality data is loaded. Run `make demo` or `make refresh`.")
    st.stop()

label_to_code = dict(zip(options["municipality_name"], options["municipality_code"], strict=True))
selected_name = st.sidebar.selectbox("Municipality", list(label_to_code))
selected_code = str(label_to_code[selected_name])
history = scorecard(selected_code)

if history.empty:
    st.warning("No scorecard observations match the selected municipality.")
    st.stop()

year_options = history["year"].astype(int).tolist()
year = st.sidebar.select_slider("Reference year", options=year_options, value=max(year_options))
latest = history.loc[history["year"] == year].iloc[0]

population = int(latest["population"])
growth = latest["population_growth_rate"]
cost = latest["eldercare_cost_per_resident"]
satisfaction = latest["eldercare_satisfaction_pct"]

c1, c2, c3, c4 = st.columns(4)
c1.metric("Population", f"{population:,.0f}")
c2.metric("Annual growth", "n/a" if pd.isna(growth) else f"{growth:.2%}")
c3.metric("Eldercare cost / resident", "n/a" if pd.isna(cost) else f"SEK {cost:,.0f}")
c4.metric("Eldercare perception", "n/a" if pd.isna(satisfaction) else f"{satisfaction:.1f}%")

overview_tab, demographics_tab, elections_tab, quality_tab = st.tabs(
    ["Trends & peers", "Demographics", "Elections", "Data quality"]
)

with overview_tab:
    left, right = st.columns(2)
    with left:
        trend = px.line(
            history,
            x="year",
            y="population",
            markers=True,
            title=f"Population trend — {selected_name}",
        )
        st.plotly_chart(trend, use_container_width=True)
    with right:
        peer_data = peers(int(year))
        peer_chart = px.scatter(
            peer_data,
            x="eldercare_cost_per_resident",
            y="eldercare_satisfaction_pct",
            color="population_growth_rate",
            hover_name="municipality_name",
            title=f"Cost, satisfaction, and growth — {year}",
        )
        st.plotly_chart(peer_chart, use_container_width=True)
    st.dataframe(peer_data, hide_index=True, use_container_width=True)

with demographics_tab:
    demographic_data = demographics(selected_code, int(year))
    if demographic_data.empty:
        st.info("No demographic observations are available for this year.")
    else:
        chart = px.bar(
            demographic_data,
            x="age_band",
            y="population",
            color="sex",
            barmode="group",
            title=f"Population by age band and sex — {year}",
        )
        st.plotly_chart(chart, use_container_width=True)
        st.dataframe(demographic_data, hide_index=True, use_container_width=True)

with elections_tab:
    election_data = elections(selected_code)
    if election_data.empty:
        st.info("No municipal election observations are available.")
    else:
        chart = px.line(
            election_data,
            x="election_year",
            y="vote_share",
            color="party_name",
            markers=True,
            title="Municipal election vote share",
        )
        chart.update_yaxes(tickformat=".0%")
        st.plotly_chart(chart, use_container_width=True)
        st.dataframe(election_data, hide_index=True, use_container_width=True)

with quality_tab:
    st.subheader("Warehouse assertions")
    st.dataframe(quality_checks(), hide_index=True, use_container_width=True)
    st.subheader("Source freshness and loaded row counts")
    st.dataframe(freshness(), hide_index=True, use_container_width=True)
    st.caption(
        "Fixture mode is deterministic and intentionally compact. "
        "Live mode preserves source batch metadata."
    )
