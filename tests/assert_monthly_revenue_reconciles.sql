-- The monthly rollup must equal the item-level total, to the cent.
with a as (select sum(net_revenue) as t from {{ ref('fct_order_items') }}),
     b as (select sum(net_revenue) as t from {{ ref('fct_monthly_revenue') }})
select a.t as item_total, b.t as monthly_total
from a, b
where abs(a.t - b.t) > 0.01
