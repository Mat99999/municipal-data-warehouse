select
    {{ surrogate_key(['p.municipality_code', 'p.year', 'p.sex', 'p.age_band']) }}
        as population_fact_key,
    m.municipality_key,
    p.year as year_key,
    d.demographic_key,
    p.population_count,
    p.batch_id,
    p.loaded_at
from {{ ref('stg_population') }} as p
inner join {{ ref('dim_municipality') }} as m
    on p.municipality_code = m.municipality_code and m.is_current
inner join {{ ref('dim_demographic') }} as d
    on p.sex = d.sex and p.age_band = d.age_band
