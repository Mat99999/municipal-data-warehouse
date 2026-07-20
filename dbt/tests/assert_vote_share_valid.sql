select * from {{ ref('fact_election_result') }}
where vote_share < 0 or vote_share > 1
