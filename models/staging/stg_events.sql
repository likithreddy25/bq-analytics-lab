select
    id as event_id,
    user_id,            -- null for anonymous browsing
    session_id,
    sequence_number,
    created_at as event_at,
    event_type,
    traffic_source,
    uri
from {{ source('thelook', 'events') }}
