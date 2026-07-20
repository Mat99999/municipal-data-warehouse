select
    f.municipality_key,
    f.year_key,
    max(f.value) filter (where m.kpi_id = 'N20043') as eldercare_cost_per_resident,
    max(f.value) filter (where m.kpi_id = 'N00533') as eldercare_satisfaction_pct,
    max(f.value) filter (where m.kpi_id = 'N00901') as municipal_tax_rate
from {{ ref('fact_municipal_kpi') }} as f
inner join {{ ref('dim_metric') }} as m on f.metric_key = m.metric_key
group by f.municipality_key, f.year_key
