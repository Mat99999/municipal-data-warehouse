-- Transaction pattern for an atomic publication boundary.
BEGIN;
LOCK TABLE raw.population IN SHARE ROW EXCLUSIVE MODE;

-- A production incremental load would MERGE validated staging rows here.
-- The assertion aborts publication if the source grain is duplicated.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM raw.population
        GROUP BY municipality_code, year, sex, age
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Population source grain is not unique';
    END IF;
END $$;

COMMIT;

