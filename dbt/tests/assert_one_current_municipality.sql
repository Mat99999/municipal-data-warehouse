select municipality_code
from {{ ref('dim_municipality') }}
group by municipality_code
having count(*) filter (where is_current) != 1
