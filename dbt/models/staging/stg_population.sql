select
    trim(municipality_code) as municipality_code,
    year::integer as year,
    lower(sex) as sex,
    case
        when age between 0 and 17 then '0-17'
        when age between 18 and 64 then '18-64'
        when age between 65 and 79 then '65-79'
        else '80+'
    end as age_band,
    sum(population_count)::bigint as population_count,
    max(batch_id::text)::uuid as batch_id,
    max(source_name) as source_name,
    max(loaded_at) as loaded_at
from {{ source('raw', 'population') }}
where population_count is not null
group by 1, 2, 3, 4
