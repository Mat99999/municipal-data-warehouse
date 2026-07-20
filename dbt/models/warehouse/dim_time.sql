with years as (
    select year from {{ ref('stg_population') }}
    union
    select year from {{ ref('stg_municipal_kpi') }}
    union
    select election_year as year from {{ ref('stg_election_results') }}
)

select
    year as year_key,
    year,
    make_date(year, 1, 1) as year_start_date,
    make_date(year, 12, 31) as year_end_date,
    year % 4 = 2 as is_swedish_general_election_year
from years
