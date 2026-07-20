# Contributing

Open an issue describing the business question, authoritative source, grain, and expected tests before adding a domain. Keep extraction in Python, transformations in dbt, and presentation logic in the dashboard. New metrics require a definition, unit, additivity rule, source owner, and reconciliation test.

Before opening a pull request, run `make demo`, `make test`, and `make lint`. Commits should be small, imperative, and explain one coherent change.

