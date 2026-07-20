-- FULL JOIN exposes mismatched source coverage at the municipality-year grain.
WITH population_coverage AS (
    SELECT DISTINCT municipality_key, year_key FROM warehouse.fact_population
), kpi_coverage AS (
    SELECT DISTINCT municipality_key, year_key FROM warehouse.fact_municipal_kpi
)
SELECT
    COALESCE(p.municipality_key, k.municipality_key) AS municipality_key,
    COALESCE(p.year_key, k.year_key) AS year_key,
    CASE
        WHEN p.municipality_key IS NULL THEN 'missing_population'
        WHEN k.municipality_key IS NULL THEN 'missing_kpi'
        ELSE 'covered_by_both'
    END AS coverage_status
FROM population_coverage p
FULL JOIN kpi_coverage k USING (municipality_key, year_key);

-- INTERSECT: grains covered by both sources.
SELECT municipality_key, year_key FROM warehouse.fact_population
INTERSECT
SELECT municipality_key, year_key FROM warehouse.fact_municipal_kpi;

-- EXCEPT: municipalities present in population but absent from KPI observations.
SELECT municipality_key FROM warehouse.fact_population
EXCEPT
SELECT municipality_key FROM warehouse.fact_municipal_kpi;

-- UNION: lineage-oriented inventory across facts.
SELECT 'population' AS fact, batch_id FROM warehouse.fact_population
UNION
SELECT 'municipal_kpi', batch_id FROM warehouse.fact_municipal_kpi
UNION
SELECT 'election_result', batch_id FROM warehouse.fact_election_result;

