select
    year::integer as year,
    value::numeric(20, 4) as value,
    batch_id,
    source_name,
    loaded_at,
    trim(municipality_code) as municipality_code,
    upper(kpi_id) as kpi_id,
    trim(kpi_name) as kpi_name,
    trim(unit) as unit,
    trim(category) as category,
    lower(sex) as sex
from {{ source('raw', 'municipal_kpi') }}
