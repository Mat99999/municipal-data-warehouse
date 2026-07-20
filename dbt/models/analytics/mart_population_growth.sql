with annual as (
    select municipality_key, year_key, sum(population_count) as population
    from {{ ref('fact_population') }}
    group by municipality_key, year_key
),

trends as (
    select
        municipality_key,
        year_key,
        population,
        lag(population) over (partition by municipality_key order by year_key) as prior_population,
        avg(population) over (
            partition by municipality_key order by year_key rows between 2 preceding and current row
        ) as population_moving_avg_3y
    from annual
)

select
    municipality_key,
    year_key,
    population,
    prior_population,
    population_moving_avg_3y,
    (population - prior_population)::numeric
    / nullif(prior_population, 0) as population_growth_rate
from trends
