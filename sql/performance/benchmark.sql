\timing on
\pset pager off

SELECT 'table cardinalities' AS benchmark;
SELECT
    (SELECT count(*) FROM warehouse.fact_population) AS population_rows,
    (SELECT count(*) FROM warehouse.fact_municipal_kpi) AS kpi_rows,
    (SELECT count(*) FROM analytics.mv_municipality_scorecard) AS scorecard_rows;

SELECT 'fact aggregation without secondary index (transactional experiment)' AS benchmark;
BEGIN;
DROP INDEX warehouse.ix_population_municipality_year;
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT municipality_key, year_key, SUM(population_count)
FROM warehouse.fact_population
WHERE municipality_key = (
    SELECT municipality_key FROM warehouse.dim_municipality
    WHERE municipality_code = '0180' AND is_current
)
AND year_key BETWEEN 2022 AND 2024
GROUP BY municipality_key, year_key;
ROLLBACK;

SELECT 'same fact aggregation with covering index available' AS benchmark;
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT municipality_key, year_key, SUM(population_count)
FROM warehouse.fact_population
WHERE municipality_key = (
    SELECT municipality_key FROM warehouse.dim_municipality
    WHERE municipality_code = '0180' AND is_current
)
AND year_key BETWEEN 2022 AND 2024
GROUP BY municipality_key, year_key;

SELECT 'materialized scorecard lookup' AS benchmark;
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT *
FROM analytics.mv_municipality_scorecard
WHERE municipality_code = '0180' AND year = 2024;
