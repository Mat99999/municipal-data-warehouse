SHELL := /bin/sh
.DEFAULT_GOAL := help

.PHONY: help bootstrap demo refresh transform test lint benchmark docs dashboard down reset
help:
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "%-16s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bootstrap: ## Build images and start PostgreSQL
	test -f .env || cp .env.example .env
	mkdir -p artifacts
	docker compose up -d --build postgres

demo: bootstrap ## Deterministic offline build from committed fixtures
	docker compose run --rm pipeline --mode fixture
	docker compose run --rm --entrypoint dbt pipeline run --select staging --project-dir dbt --profiles-dir dbt
	docker compose run --rm --entrypoint dbt pipeline snapshot --project-dir dbt --profiles-dir dbt
	docker compose run --rm --entrypoint dbt pipeline build --project-dir dbt --profiles-dir dbt
	docker compose exec -T postgres psql -U "$${POSTGRES_USER:-warehouse_admin}" -d "$${POSTGRES_DB:-municipal_dw}" -f /app/sql/serving.sql
	docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U "$${POSTGRES_USER:-warehouse_admin}" -d "$${POSTGRES_DB:-municipal_dw}" -f /app/sql/tests/end_to_end.sql

refresh: bootstrap ## Refresh all configured live sources and rebuild models
	docker compose run --rm pipeline --mode live
	docker compose run --rm --entrypoint dbt pipeline run --select staging --project-dir dbt --profiles-dir dbt
	docker compose run --rm --entrypoint dbt pipeline snapshot --project-dir dbt --profiles-dir dbt
	docker compose run --rm --entrypoint dbt pipeline build --project-dir dbt --profiles-dir dbt
	docker compose exec -T postgres psql -U "$${POSTGRES_USER:-warehouse_admin}" -d "$${POSTGRES_DB:-municipal_dw}" -f /app/sql/serving.sql
	docker compose exec -T postgres psql -v ON_ERROR_STOP=1 -U "$${POSTGRES_USER:-warehouse_admin}" -d "$${POSTGRES_DB:-municipal_dw}" -f /app/sql/tests/end_to_end.sql

test: ## Run unit, SQL style, and warehouse tests
	docker compose run --rm --entrypoint pytest pipeline
	docker compose run --rm --entrypoint dbt pipeline test --project-dir dbt --profiles-dir dbt

lint: ## Run Python and SQL static checks
	docker compose run --rm --entrypoint ruff pipeline check src tests dashboard
	docker compose run --rm --entrypoint sqlfluff pipeline lint dbt/models --templater dbt

benchmark: ## Capture PostgreSQL query plans in artifacts/
	mkdir -p artifacts
	docker compose exec -T postgres psql -U "$${POSTGRES_USER:-warehouse_admin}" -d "$${POSTGRES_DB:-municipal_dw}" -f /app/sql/performance/benchmark.sql > artifacts/benchmark.txt

docs: ## Generate dbt catalog and lineage site
	docker compose run --rm --entrypoint dbt pipeline docs generate --project-dir dbt --profiles-dir dbt

dashboard: ## Start the local Streamlit dashboard
	docker compose up -d --build dashboard

down: ## Stop services while retaining the database volume
	docker compose down

reset: ## Delete the local database volume; explicit destructive command
	docker compose down -v
