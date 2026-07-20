select
    batch_id,
    source_name,
    loaded_at,
    trim(municipality_code) as municipality_code,
    trim(municipality_name) as municipality_name,
    trim(region_code) as region_code,
    trim(region_name) as region_name
from {{ source('raw', 'municipality') }}
