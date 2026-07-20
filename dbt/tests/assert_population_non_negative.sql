select * from {{ ref('fact_population') }}
where population_count < 0
