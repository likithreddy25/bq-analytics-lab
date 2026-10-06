-- Grain: one row per calendar month. Splits active customers into new vs returning.
with items as (
    select * from {{ ref('fct_order_items') }}
),
first_order_month as (
    select
        user_id,
        min(order_month) as cohort_month
    from items
    where not is_cancelled
    group by user_id
),
monthly as (
    select
        i.order_month,
        count(distinct if(not i.is_cancelled, i.order_id, null)) as orders,
        countif(not i.is_cancelled) as items_sold,
        sum(i.gross_amount) as gross_amount,
        sum(i.net_revenue) as net_revenue,
        sum(i.gross_margin) as gross_margin,
        countif(i.is_returned) as returned_items,
        count(distinct if(not i.is_cancelled, i.user_id, null)) as active_customers,
        count(distinct if(not i.is_cancelled and f.cohort_month = i.order_month, i.user_id, null)) as new_customers
    from items i
    left join first_order_month f using (user_id)
    group by i.order_month
)
select
    *,
    active_customers - new_customers as returning_customers,
    safe_divide(net_revenue, orders) as avg_order_value,
    safe_divide(returned_items, items_sold) as return_rate
from monthly
