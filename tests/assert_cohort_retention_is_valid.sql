-- Retention is a proportion, and month 0 is always 100% of the cohort.
select *
from {{ ref('fct_cohort_retention') }}
where retention_rate < 0
   or retention_rate > 1
   or (months_since_first = 0 and abs(retention_rate - 1) > 1e-9)
