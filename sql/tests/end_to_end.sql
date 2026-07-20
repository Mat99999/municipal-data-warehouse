-- Deployment-level assertions run after dbt and serving objects have been built.
DO $$
DECLARE
    duplicate_count bigint;
BEGIN
    IF NOT EXISTS (SELECT FROM raw.population) THEN
        RAISE EXCEPTION 'raw.population is empty';
    END IF;
    IF NOT EXISTS (SELECT FROM warehouse.fact_population) THEN
        RAISE EXCEPTION 'warehouse.fact_population is empty';
    END IF;
    IF NOT EXISTS (SELECT FROM analytics.mv_municipality_scorecard) THEN
        RAISE EXCEPTION 'analytics.mv_municipality_scorecard is empty';
    END IF;

    SELECT count(*) INTO duplicate_count
    FROM (
        SELECT municipality_code, year, sex, age, count(*)
        FROM raw.population
        GROUP BY municipality_code, year, sex, age
        HAVING count(*) > 1
    ) duplicates;
    IF duplicate_count > 0 THEN
        RAISE EXCEPTION 'raw.population contains % duplicate grains', duplicate_count;
    END IF;

    IF NOT has_table_privilege(
        'dashboard_reader', 'analytics.mv_municipality_scorecard', 'SELECT'
    ) THEN
        RAISE EXCEPTION 'dashboard_reader cannot read the scorecard';
    END IF;
    IF has_table_privilege('dashboard_reader', 'raw.population', 'SELECT') THEN
        RAISE EXCEPTION 'dashboard_reader unexpectedly has raw access';
    END IF;
END $$;

SELECT 'end-to-end assertions passed' AS result;
