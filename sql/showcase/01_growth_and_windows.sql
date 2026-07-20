-- Business question: which municipalities are growing fastest, and is growth persistent?
WITH annual AS (
    SELECT municipality_key, year_key, SUM(population_count) AS population
    FROM warehouse.fact_population
    GROUP BY municipality_key, year_key
), movement AS (
    SELECT
        municipality_key,
        year_key,
        population,
        LAG(population) OVER (PARTITION BY municipality_key ORDER BY year_key) AS prior_population,
        LEAD(population) OVER (PARTITION BY municipality_key ORDER BY year_key) AS next_population,
        AVG(population) OVER (
            PARTITION BY municipality_key ORDER BY year_key ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS moving_average_3y
    FROM annual
)
SELECT
    m.municipality_name,
    movement.*,
    (population - prior_population)::numeric / NULLIF(prior_population, 0) AS annual_growth,
    DENSE_RANK() OVER (
        PARTITION BY year_key ORDER BY (population - prior_population)::numeric / NULLIF(prior_population, 0) DESC
    ) AS growth_rank,
    PERCENT_RANK() OVER (
        PARTITION BY year_key ORDER BY (population - prior_population)::numeric / NULLIF(prior_population, 0)
    ) AS growth_percentile
FROM movement
JOIN warehouse.dim_municipality m USING (municipality_key)
WHERE m.is_current
ORDER BY year_key, growth_rank;

