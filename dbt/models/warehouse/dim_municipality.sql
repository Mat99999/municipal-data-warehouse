select
    {{ surrogate_key(['municipality_code', 'dbt_valid_from']) }} as municipality_key,
    municipality_code,
    municipality_name,
    {{ surrogate_key(['region_code']) }} as region_key,
    region_code,
    dbt_valid_from::timestamptz as valid_from,
    coalesce(dbt_valid_to, '9999-12-31'::timestamptz) as valid_to,
    dbt_valid_to is null as is_current
from {{ ref('municipality_snapshot') }}
