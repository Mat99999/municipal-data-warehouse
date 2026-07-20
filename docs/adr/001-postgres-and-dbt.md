# ADR-001: PostgreSQL and dbt Core

**Status:** accepted

PostgreSQL is used instead of an embedded engine because the portfolio must demonstrate database constraints, roles, transactions, materialized views, indexes, and query plans. dbt owns SQL transformations, tests, lineage, and snapshots; Python is restricted to extraction, validation, and loading.

