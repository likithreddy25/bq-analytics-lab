select
    id as user_id,
    age,
    gender,
    state,
    country,
    traffic_source,
    created_at as signed_up_at
from {{ source('thelook', 'users') }}
