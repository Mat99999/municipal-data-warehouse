select
    'population_non_negative'::text as check_name,
    count(*) filter (where population_count < 0)::bigint as violation_count,
    'Population counts must be zero or greater'::text as expectation
from {{ ref('fact_population') }}

union all

select
    'election_vote_share_range' as check_name,
    count(*) filter (where vote_share < 0 or vote_share > 1)::bigint as violation_count,
    'Vote share must be between zero and one' as expectation
from {{ ref('fact_election_result') }}

union all

select
    'one_current_municipality_version' as check_name,
    count(*)::bigint as violation_count,
    'Every municipality code has exactly one current Type-2 row' as expectation
from (
    select municipality_code
    from {{ ref('dim_municipality') }}
    group by municipality_code
    having count(*) filter (where is_current) != 1
) as violations
