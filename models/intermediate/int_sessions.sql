-- One row per web session, rolled up from raw events.
select
    session_id,
    max(user_id) as user_id,
    min(event_at) as session_started_at,
    max(event_at) as session_ended_at,
    count(*) as event_count,
    countif(event_type = 'product') as product_views,
    countif(event_type = 'cart') as cart_events,
    countif(event_type = 'purchase') > 0 as has_purchase
from {{ ref('stg_events') }}
group by session_id
