select
    {{ surrogate_key(['e.municipality_code', 'e.election_year', 'e.party_code']) }}
        as election_fact_key,
    m.municipality_key,
    e.election_year as year_key,
    p.party_key,
    e.eligible_voters,
    e.valid_votes,
    e.party_votes,
    e.seats,
    e.vote_share,
    e.batch_id,
    e.loaded_at
from {{ ref('stg_election_results') }} as e
inner join {{ ref('dim_municipality') }} as m
    on e.municipality_code = m.municipality_code and m.is_current
inner join {{ ref('dim_party') }} as p on e.party_code = p.party_code
