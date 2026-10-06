-- Grain: one row per customer, with lifetime value, engagement, and a health segment.
with users as (
    select * from {{ ref('stg_users') }}
),
orders as (
    select
        user_id,
        min(ordered_at) as first_order_at,
        max(ordered_at) as last_order_at,
        count(distinct if(not is_cancelled, order_id, null)) as lifetime_orders,
        sum(net_revenue) as lifetime_net_revenue,
        countif(is_returned) as returned_items,
        countif(not is_cancelled) as purchased_items
    from {{ ref('fct_order_items') }}
    group by user_id
),
sessions as (
    select
        user_id,
        count(*) as session_count,
        max(session_ended_at) as last_session_at
    from {{ ref('int_sessions') }}
    where user_id is not null
    group by user_id
),
joined as (
    select
        u.user_id,
        u.age,
        u.gender,
        u.state,
        u.country,
        u.traffic_source,
        u.signed_up_at,
        o.first_order_at,
        o.last_order_at,
        coalesce(o.lifetime_orders, 0) as lifetime_orders,
        coalesce(o.lifetime_net_revenue, 0) as lifetime_net_revenue,
        coalesce(o.returned_items, 0) as returned_items,
        safe_divide(o.returned_items, o.purchased_items) as return_rate,
        coalesce(s.session_count, 0) as session_count,
        s.last_session_at,
        date_diff({{ as_of_date() }}, date(o.last_order_at), day) as days_since_last_order
    from users u
    left join orders o using (user_id)
    left join sessions s using (user_id)
)
select
    *,
    case
        when lifetime_orders = 0 then 'never_purchased'
        when days_since_last_order <= {{ var('health_active_days') }} then 'active'
        when days_since_last_order <= {{ var('health_cooling_days') }} then 'cooling'
        when days_since_last_order <= {{ var('health_at_risk_days') }} then 'at_risk'
        else 'churned'
    end as health_segment
from joined
