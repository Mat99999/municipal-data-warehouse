select
    e.municipality_key,
    m.municipality_code,
    m.municipality_name,
    e.year_key,
    p.party_code,
    p.party_name,
    e.vote_share,
    e.seats,
    e.vote_share - lag(e.vote_share) over (
        partition by e.municipality_key, e.party_key order by e.year_key
    ) as vote_share_change,
    dense_rank() over (
        partition by e.municipality_key, e.year_key order by e.vote_share desc
    ) as party_rank
from {{ ref('fact_election_result') }} as e
inner join {{ ref('dim_party') }} as p on e.party_key = p.party_key
inner join {{ ref('dim_municipality') }} as m on e.municipality_key = m.municipality_key
where m.is_current
