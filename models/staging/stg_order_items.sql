select
    id as order_item_id,
    order_id,
    user_id,
    product_id,
    status,
    created_at as ordered_at,
    shipped_at,
    delivered_at,
    returned_at,
    sale_price
from {{ source('thelook', 'order_items') }}
