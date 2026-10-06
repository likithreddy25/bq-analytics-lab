-- Grain: cohort_month x months_since_first. Share of a cohort that ordered again in month N.
with activity as (
    select distinct user_id, order_month
    from {{ ref('fct_order_items') }}
    where not is_cancelled
),
cohorts as (
    select user_id, min(order_month) as cohort_month
    from activity
    group by user_id
),
sizes as (
    select cohort_month, count(*) as cohort_size
    from cohorts
    group by cohort_month
),
retained as (
    select
        c.cohort_month,
        date_diff(a.order_month, c.cohort_month, month) as months_since_first,
        count(distinct a.user_id) as active_customers
    from activity a
    join cohorts c using (user_id)
    group by c.cohort_month, months_since_first
)
select
    r.cohort_month,
    r.months_since_first,
    r.active_customers,
    s.cohort_size,
    safe_divide(r.active_customers, s.cohort_size) as retention_rate
from retained r
join sizes s using (cohort_month)
