select
    month_start,
    account_id,
    lower(segment) as segment,
    lower(plan) as plan_name,
    lower(billing_period) as billing_period,
    mrr,
    active_seats,
    feature_adopted as feature_adopted_flag,
    usage_multiplier,
    health_score,
    user_id_start,
    user_capacity,
    lower(acquisition_channel) as acquisition_channel,
    region,
    iff(mrr > 0, true, false) as is_active_subscription,
    iff(feature_adopted = 1, true, false) as has_adopted_key_feature,
    round(active_seats / nullif(user_capacity, 0), 4) as seat_utilization_pct
from {{ source('raw', 'subscription_monthly_snapshot') }}