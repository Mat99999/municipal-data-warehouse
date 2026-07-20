CREATE INDEX IF NOT EXISTS ix_population_municipality_year
    ON warehouse.fact_population (municipality_key, year_key)
    INCLUDE (population_count);
CREATE INDEX IF NOT EXISTS ix_kpi_metric_year_municipality
    ON warehouse.fact_municipal_kpi (metric_key, year_key, municipality_key)
    INCLUDE (value);
CREATE INDEX IF NOT EXISTS ix_election_year_party_municipality
    ON warehouse.fact_election_result (year_key, party_key, municipality_key);

DROP MATERIALIZED VIEW IF EXISTS analytics.mv_municipality_scorecard;
CREATE MATERIALIZED VIEW analytics.mv_municipality_scorecard AS
SELECT * FROM analytics.mart_municipality_year;
CREATE UNIQUE INDEX ux_mv_municipality_scorecard
    ON analytics.mv_municipality_scorecard (municipality_key, year);

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dashboard_reader') THEN
        CREATE ROLE dashboard_reader LOGIN PASSWORD 'dashboard_reader_password';
    END IF;
END $$;
DO $$ BEGIN
    EXECUTE format(
        'GRANT CONNECT ON DATABASE %I TO dashboard_reader',
        current_database()
    );
END $$;
GRANT USAGE ON SCHEMA analytics TO dashboard_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO dashboard_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT ON TABLES TO dashboard_reader;

-- Drop dependent keys first so this script can be rerun without a dbt rebuild.
ALTER TABLE warehouse.fact_population DROP CONSTRAINT IF EXISTS fk_population_municipality;
ALTER TABLE warehouse.fact_population DROP CONSTRAINT IF EXISTS fk_population_time;
ALTER TABLE warehouse.fact_population DROP CONSTRAINT IF EXISTS fk_population_demographic;
ALTER TABLE warehouse.fact_municipal_kpi DROP CONSTRAINT IF EXISTS fk_kpi_municipality;
ALTER TABLE warehouse.fact_municipal_kpi DROP CONSTRAINT IF EXISTS fk_kpi_time;
ALTER TABLE warehouse.fact_municipal_kpi DROP CONSTRAINT IF EXISTS fk_kpi_metric;
ALTER TABLE warehouse.fact_municipal_kpi DROP CONSTRAINT IF EXISTS fk_kpi_demographic;
ALTER TABLE warehouse.fact_election_result DROP CONSTRAINT IF EXISTS fk_election_municipality;
ALTER TABLE warehouse.fact_election_result DROP CONSTRAINT IF EXISTS fk_election_time;
ALTER TABLE warehouse.fact_election_result DROP CONSTRAINT IF EXISTS fk_election_party;
ALTER TABLE warehouse.dim_municipality DROP CONSTRAINT IF EXISTS fk_municipality_region;

ALTER TABLE warehouse.dim_region DROP CONSTRAINT IF EXISTS pk_dim_region;
ALTER TABLE warehouse.dim_region ADD CONSTRAINT pk_dim_region PRIMARY KEY (region_key);
ALTER TABLE warehouse.dim_municipality DROP CONSTRAINT IF EXISTS pk_dim_municipality;
ALTER TABLE warehouse.dim_municipality ADD CONSTRAINT pk_dim_municipality PRIMARY KEY (municipality_key);
ALTER TABLE warehouse.dim_time DROP CONSTRAINT IF EXISTS pk_dim_time;
ALTER TABLE warehouse.dim_time ADD CONSTRAINT pk_dim_time PRIMARY KEY (year_key);
ALTER TABLE warehouse.dim_demographic DROP CONSTRAINT IF EXISTS pk_dim_demographic;
ALTER TABLE warehouse.dim_demographic ADD CONSTRAINT pk_dim_demographic PRIMARY KEY (demographic_key);
ALTER TABLE warehouse.dim_metric DROP CONSTRAINT IF EXISTS pk_dim_metric;
ALTER TABLE warehouse.dim_metric ADD CONSTRAINT pk_dim_metric PRIMARY KEY (metric_key);
ALTER TABLE warehouse.dim_party DROP CONSTRAINT IF EXISTS pk_dim_party;
ALTER TABLE warehouse.dim_party ADD CONSTRAINT pk_dim_party PRIMARY KEY (party_key);
ALTER TABLE warehouse.dim_municipality ADD CONSTRAINT fk_municipality_region
    FOREIGN KEY (region_key) REFERENCES warehouse.dim_region(region_key);

ALTER TABLE warehouse.fact_population DROP CONSTRAINT IF EXISTS pk_fact_population;
ALTER TABLE warehouse.fact_population DROP CONSTRAINT IF EXISTS fk_population_municipality;
ALTER TABLE warehouse.fact_population DROP CONSTRAINT IF EXISTS fk_population_time;
ALTER TABLE warehouse.fact_population DROP CONSTRAINT IF EXISTS fk_population_demographic;
ALTER TABLE warehouse.fact_population ADD CONSTRAINT pk_fact_population PRIMARY KEY (population_fact_key);
ALTER TABLE warehouse.fact_population ADD CONSTRAINT fk_population_municipality
    FOREIGN KEY (municipality_key) REFERENCES warehouse.dim_municipality(municipality_key);
ALTER TABLE warehouse.fact_population ADD CONSTRAINT fk_population_time
    FOREIGN KEY (year_key) REFERENCES warehouse.dim_time(year_key);
ALTER TABLE warehouse.fact_population ADD CONSTRAINT fk_population_demographic
    FOREIGN KEY (demographic_key) REFERENCES warehouse.dim_demographic(demographic_key);

ALTER TABLE warehouse.fact_municipal_kpi DROP CONSTRAINT IF EXISTS pk_fact_municipal_kpi;
ALTER TABLE warehouse.fact_municipal_kpi DROP CONSTRAINT IF EXISTS fk_kpi_municipality;
ALTER TABLE warehouse.fact_municipal_kpi DROP CONSTRAINT IF EXISTS fk_kpi_time;
ALTER TABLE warehouse.fact_municipal_kpi DROP CONSTRAINT IF EXISTS fk_kpi_metric;
ALTER TABLE warehouse.fact_municipal_kpi DROP CONSTRAINT IF EXISTS fk_kpi_demographic;
ALTER TABLE warehouse.fact_municipal_kpi ADD CONSTRAINT pk_fact_municipal_kpi PRIMARY KEY (municipal_kpi_fact_key);
ALTER TABLE warehouse.fact_municipal_kpi ADD CONSTRAINT fk_kpi_municipality
    FOREIGN KEY (municipality_key) REFERENCES warehouse.dim_municipality(municipality_key);
ALTER TABLE warehouse.fact_municipal_kpi ADD CONSTRAINT fk_kpi_time
    FOREIGN KEY (year_key) REFERENCES warehouse.dim_time(year_key);
ALTER TABLE warehouse.fact_municipal_kpi ADD CONSTRAINT fk_kpi_metric
    FOREIGN KEY (metric_key) REFERENCES warehouse.dim_metric(metric_key);
ALTER TABLE warehouse.fact_municipal_kpi ADD CONSTRAINT fk_kpi_demographic
    FOREIGN KEY (demographic_key) REFERENCES warehouse.dim_demographic(demographic_key);
ALTER TABLE warehouse.fact_election_result DROP CONSTRAINT IF EXISTS pk_fact_election_result;
ALTER TABLE warehouse.fact_election_result DROP CONSTRAINT IF EXISTS fk_election_municipality;
ALTER TABLE warehouse.fact_election_result DROP CONSTRAINT IF EXISTS fk_election_time;
ALTER TABLE warehouse.fact_election_result DROP CONSTRAINT IF EXISTS fk_election_party;
ALTER TABLE warehouse.fact_election_result ADD CONSTRAINT pk_fact_election_result PRIMARY KEY (election_fact_key);
ALTER TABLE warehouse.fact_election_result ADD CONSTRAINT fk_election_municipality
    FOREIGN KEY (municipality_key) REFERENCES warehouse.dim_municipality(municipality_key);
ALTER TABLE warehouse.fact_election_result ADD CONSTRAINT fk_election_time
    FOREIGN KEY (year_key) REFERENCES warehouse.dim_time(year_key);
ALTER TABLE warehouse.fact_election_result ADD CONSTRAINT fk_election_party
    FOREIGN KEY (party_key) REFERENCES warehouse.dim_party(party_key);
