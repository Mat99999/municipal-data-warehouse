# ADR-002: Do not partition v1 facts

**Status:** accepted

The expected fact cardinality is well within a single PostgreSQL table's practical range. Year partitioning would add DDL, routing, and maintenance cost without demonstrated benefit. Reconsider when the largest fact reaches tens of millions of rows, retention operations become a bottleneck, or benchmark evidence shows consistent partition pruning value.

