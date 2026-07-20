select
    election_year::integer as election_year,
    eligible_voters::bigint as eligible_voters,
    valid_votes::bigint as valid_votes,
    party_votes::bigint as party_votes,
    seats::integer as seats,
    batch_id,
    source_name,
    loaded_at,
    trim(municipality_code) as municipality_code,
    upper(trim(party_code)) as party_code,
    trim(party_name) as party_name,
    party_votes::numeric / nullif(valid_votes, 0) as vote_share
from {{ source('raw', 'election_result') }}
