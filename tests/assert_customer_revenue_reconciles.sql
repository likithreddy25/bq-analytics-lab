-- Customer-level lifetime revenue must add up to the order-item total.
with a as (select sum(net_revenue) as t from {{ ref('fct_order_items') }}),
     b as (select sum(lifetime_net_revenue) as t from {{ ref('dim_customers') }})
select a.t as item_total, b.t as customer_total
from a, b
where abs(a.t - b.t) > 0.01
