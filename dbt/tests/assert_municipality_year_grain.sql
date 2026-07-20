select municipality_key, year
from {{ ref('mart_municipality_year') }}
group by municipality_key, year
having count(*) > 1
