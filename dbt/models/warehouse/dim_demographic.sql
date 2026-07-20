with variants as (
    select distinct sex, age_band from {{ ref('stg_population') }}
    union
    select distinct sex, 'not_applicable' as age_band from {{ ref('stg_municipal_kpi') }}
    union
    select 'not_applicable' as sex, 'not_applicable' as age_band
)
select
    {{ surrogate_key(['sex', 'age_band']) }} as demographic_key,
    sex,
    age_band
from variants
