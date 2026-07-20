select distinct
    {{ surrogate_key(['region_code']) }} as region_key,
    region_code,
    region_name
from {{ ref('stg_municipalities') }}
