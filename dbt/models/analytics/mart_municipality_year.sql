select
    p.municipality_key,
    m.municipality_code,
    m.municipality_name,
    m.region_code,
    r.region_name,
    p.year_key as year,
    p.population,
    p.population_growth_rate,
    p.population_moving_avg_3y,
    e.eldercare_cost_per_resident,
    e.eldercare_satisfaction_pct,
    e.municipal_tax_rate,
    percent_rank()
        over (partition by p.year_key order by p.population_growth_rate)
        as growth_percentile,
    avg(p.population_growth_rate) over (partition by p.year_key) as national_avg_growth_rate
from {{ ref('mart_population_growth') }} as p
inner join {{ ref('dim_municipality') }} as m on p.municipality_key = m.municipality_key
inner join {{ ref('dim_region') }} as r on m.region_key = r.region_key
left join {{ ref('mart_eldercare_efficiency') }} as e
    on p.municipality_key = e.municipality_key and p.year_key = e.year_key
where m.is_current
