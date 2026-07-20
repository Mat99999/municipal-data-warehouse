select
    source_name,
    max(loaded_at) as last_loaded_at,
    count(*) as raw_rows
from (
    select source_name, loaded_at from {{ source('raw', 'population') }}
    union all
    select source_name, loaded_at from {{ source('raw', 'municipal_kpi') }}
    union all
    select source_name, loaded_at from {{ source('raw', 'election_result') }}
) as observations
group by source_name
