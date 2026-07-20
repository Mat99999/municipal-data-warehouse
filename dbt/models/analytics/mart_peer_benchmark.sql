select
    municipality_key,
    municipality_code,
    municipality_name,
    region_name,
    year,
    population,
    population_growth_rate,
    eldercare_cost_per_resident,
    eldercare_satisfaction_pct,
    ntile(4) over (partition by year order by population) as population_quartile,
    percent_rank() over (partition by year order by eldercare_cost_per_resident) as cost_percentile,
    eldercare_cost_per_resident - avg(eldercare_cost_per_resident) over (partition by year)
        as cost_deviation_from_national_mean
from {{ ref('mart_municipality_year') }}
