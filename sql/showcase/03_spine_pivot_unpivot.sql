-- CROSS JOIN builds the expected municipality-year spine before left joining observations.
WITH spine AS (
    SELECT m.municipality_key, t.year_key
    FROM warehouse.dim_municipality m
    CROSS JOIN warehouse.dim_time t
    WHERE m.is_current AND t.year_key BETWEEN 2022 AND 2024
), pivoted AS (
    SELECT
        f.municipality_key,
        f.year_key,
        MAX(f.value) FILTER (WHERE dm.kpi_id = 'N20043') AS eldercare_cost,
        MAX(f.value) FILTER (WHERE dm.kpi_id = 'N00533') AS satisfaction
    FROM warehouse.fact_municipal_kpi f
    JOIN warehouse.dim_metric dm USING (metric_key)
    GROUP BY f.municipality_key, f.year_key
)
SELECT s.*, p.eldercare_cost, p.satisfaction
FROM spine s
LEFT JOIN pivoted p USING (municipality_key, year_key);

-- UNPIVOT a wide scorecard into a chart-friendly metric/value representation.
SELECT
    scorecard.municipality_code,
    scorecard.year,
    metrics.metric_name,
    metrics.metric_value
FROM analytics.mv_municipality_scorecard scorecard
CROSS JOIN LATERAL (
    VALUES
        ('population', scorecard.population::numeric),
        ('eldercare_cost', scorecard.eldercare_cost_per_resident::numeric),
        ('eldercare_satisfaction', scorecard.eldercare_satisfaction_pct::numeric)
) AS metrics(metric_name, metric_value);
