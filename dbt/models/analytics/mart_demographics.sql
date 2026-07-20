select
    f.municipality_key,
    m.municipality_code,
    f.year_key as year,
    d.age_band,
    d.sex,
    sum(f.population_count) as population
from {{ ref('fact_population') }} as f
inner join {{ ref('dim_municipality') }} as m on f.municipality_key = m.municipality_key
inner join {{ ref('dim_demographic') }} as d on f.demographic_key = d.demographic_key
where m.is_current
group by f.municipality_key, m.municipality_code, f.year_key, d.age_band, d.sex
