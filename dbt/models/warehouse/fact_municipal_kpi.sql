with default_demographic as (
    select demographic_key
    from {{ ref('dim_demographic') }}
    where sex = 'not_applicable' and age_band = 'not_applicable'
)

select
    {{ surrogate_key(['k.municipality_code', 'k.year', 'k.kpi_id', 'k.sex']) }}
        as municipal_kpi_fact_key,
    m.municipality_key,
    k.year as year_key,
    mt.metric_key,
    k.value,
    k.batch_id,
    k.loaded_at,
    coalesce(d.demographic_key, dna.demographic_key) as demographic_key
from {{ ref('stg_municipal_kpi') }} as k
inner join {{ ref('dim_municipality') }} as m
    on k.municipality_code = m.municipality_code and m.is_current
inner join {{ ref('dim_metric') }} as mt on k.kpi_id = mt.kpi_id
left join {{ ref('dim_demographic') }} as d
    on k.sex = d.sex and d.age_band = 'not_applicable'
cross join default_demographic as dna
