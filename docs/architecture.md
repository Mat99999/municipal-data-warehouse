# Architecture

## Design goals

The warehouse favors auditability, reproducibility, and explicit analytical grain over unnecessary platform complexity. Docker is the deployment boundary; PostgreSQL is the single query engine; Python owns source I/O; dbt owns transformations and tests.

## Data flow

1. A typed source adapter retrieves or reads a dataset and converts it into canonical Pydantic rows.
2. A batch record is opened in `raw.ingestion_batch` before data mutation.
3. All source tables are replaced in one transaction. Raw primary keys guarantee source grain, and a failed publish leaves the prior complete raw snapshot intact.
4. dbt staging views standardize values and aggregate detailed ages into governed age bands.
5. A dbt snapshot captures municipality attribute changes.
6. Warehouse dimensions and facts generate deterministic keys and enforce referential integrity.
7. Analytics marts calculate growth, peers, KPI pivots, election movement, demographics, and freshness.
8. The materialized scorecard and marts are granted to a read-only dashboard role.

## Failure boundaries

- HTTP timeouts and network errors retry with exponential jitter.
- Contract violations fail before database load.
- A failed batch is recorded with status `failed` and previously published warehouse models remain available.
- dbt tests block a successful CI result.
- Live source monitoring is separate from deterministic pull-request CI.

## Security

No source requires credentials. Local database credentials are development defaults and can be overridden through `.env`. The dashboard uses `dashboard_reader`, which has `SELECT` only on `analytics`. No individual-level data is processed.
