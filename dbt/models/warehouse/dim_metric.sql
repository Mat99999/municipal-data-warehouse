select
    {{ surrogate_key(['kpi_id']) }} as metric_key,
    kpi_id,
    max(kpi_name) as kpi_name,
    max(unit) as unit,
    max(category) as category,
    case
        when lower(max(unit)) like '%percent%' or max(unit) like '%(%)%' then 'non_additive'
        when lower(max(unit)) like '%per%' or lower(max(unit)) like '%/inv%' then 'non_additive'
        else 'additive_or_unknown'
    end as additivity
from {{ ref('stg_municipal_kpi') }}
group by kpi_id
