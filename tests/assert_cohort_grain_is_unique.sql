-- fct_cohort_retention grain is cohort_month x months_since_first; no duplicates allowed.
select cohort_month, months_since_first, count(*) as n
from {{ ref('fct_cohort_retention') }}
group by cohort_month, months_since_first
having count(*) > 1
