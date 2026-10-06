-- Grain: one row per order item. Net revenue excludes cancelled and returned items.
with items as (
    select * from {{ ref('stg_order_items') }}
),
products as (
    select * from {{ ref('stg_products') }}
)
select
    i.order_item_id,
    i.order_id,
    i.user_id,
    i.product_id,
    i.ordered_at,
    date(i.ordered_at) as ordered_date,
    date_trunc(date(i.ordered_at), month) as order_month,
    i.status,
    i.status = 'Cancelled' as is_cancelled,
    i.status = 'Returned' as is_returned,
    p.category,
    p.brand,
    p.department,
    i.sale_price as gross_amount,
    if(i.status in ('Cancelled', 'Returned'), 0, i.sale_price) as net_revenue,
    if(i.status in ('Cancelled', 'Returned'), 0, i.sale_price - p.cost) as gross_margin
from items i
left join products p using (product_id)
