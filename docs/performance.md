# Performance study

## Protocol

1. Build an unchanged fixture or live dataset with `make demo` or `make refresh`.
2. Run `make benchmark` twice; treat the first run as cold-ish and the second as cache-warm.
3. Record PostgreSQL version, Docker resources, row counts, execution time, shared buffer hits/reads, and plan operators.
4. Compare the same municipal fact aggregation after transactionally dropping the covering index and after rollback restores it; then compare the materialized scorecard lookup.
5. Store the captured plan in the CI artifact rather than claiming universal timing results in documentation.

## Index rationale

- `(municipality_key, year_key) INCLUDE (population_count)` supports municipal time-series scans.
- `(metric_key, year_key, municipality_key) INCLUDE (value)` supports KPI ranking by period.
- `(year_key, party_key, municipality_key)` supports election comparisons.
- The materialized scorecard has a unique `(municipality_key, year)` index for point lookups and safe concurrent-refresh evolution.

PostgreSQL may prefer sequential scans for the compact fixture. That is correct optimizer behavior, not a failed benchmark. The live population table gives the index study a more meaningful cardinality.
