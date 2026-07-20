CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS raw.ingestion_batch (
    batch_id uuid PRIMARY KEY,
    mode text NOT NULL CHECK (mode IN ('fixture', 'live')),
    started_at timestamptz NOT NULL,
    completed_at timestamptz,
    status text NOT NULL CHECK (status IN ('running', 'succeeded', 'failed')),
    source_manifest jsonb NOT NULL,
    row_counts jsonb
);

CREATE TABLE IF NOT EXISTS raw.municipality (
    municipality_code char(4) PRIMARY KEY,
    municipality_name text NOT NULL,
    region_code char(2) NOT NULL,
    region_name text NOT NULL,
    batch_id uuid NOT NULL REFERENCES raw.ingestion_batch(batch_id),
    source_name text NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS raw.population (
    municipality_code char(4) NOT NULL,
    year smallint NOT NULL CHECK (year BETWEEN 1968 AND 2100),
    sex text NOT NULL CHECK (sex IN ('male', 'female')),
    age smallint NOT NULL CHECK (age BETWEEN 0 AND 110),
    population_count integer NOT NULL CHECK (population_count >= 0),
    batch_id uuid NOT NULL REFERENCES raw.ingestion_batch(batch_id),
    source_name text NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (municipality_code, year, sex, age)
);

CREATE TABLE IF NOT EXISTS raw.municipal_kpi (
    municipality_code char(4) NOT NULL,
    year smallint NOT NULL,
    kpi_id varchar(6) NOT NULL,
    kpi_name text NOT NULL,
    unit text NOT NULL,
    category text NOT NULL,
    sex text NOT NULL DEFAULT 'not_applicable',
    value numeric(20, 4) NOT NULL,
    batch_id uuid NOT NULL REFERENCES raw.ingestion_batch(batch_id),
    source_name text NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (municipality_code, year, kpi_id, sex)
);

CREATE TABLE IF NOT EXISTS raw.election_result (
    municipality_code char(4) NOT NULL,
    election_year smallint NOT NULL,
    party_code text NOT NULL,
    party_name text NOT NULL,
    eligible_voters integer NOT NULL CHECK (eligible_voters >= 0),
    valid_votes integer NOT NULL CHECK (valid_votes >= 0),
    party_votes integer NOT NULL CHECK (party_votes >= 0),
    seats smallint CHECK (seats >= 0),
    batch_id uuid NOT NULL REFERENCES raw.ingestion_batch(batch_id),
    source_name text NOT NULL,
    loaded_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (municipality_code, election_year, party_code)
);
