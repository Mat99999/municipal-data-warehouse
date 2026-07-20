select
    {{ surrogate_key(['party_code']) }} as party_key,
    party_code,
    max(party_name) as party_name
from {{ ref('stg_election_results') }}
group by party_code
