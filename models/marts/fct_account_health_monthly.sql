select
    account_month_key,
    month_start,
    account_id,
    company_name,
    segment,
    acquisition_channel,
    region,
    industry,
    plan_name,
    billing_period,
    months_since_signup,
    mrr,
    active_seats,
    user_capacity,
    seat_utilization_pct,
    health_score,
    health_bucket,
    total_events,
    active_users_in_month,
    workflow_automation_events,
    dashboard_events,
    collaboration_events,
    authentication_events,
    core_usage_events,
    ticket_count,
    avg_resolution_hours,
    pct_resolved_within_24h,
    avg_csat_score,
    has_adopted_key_feature,
    at_risk_flag,
    expansion_candidate_flag,
    case
        when health_score < 40 then 'low_health_score'
        when coalesce(total_events, 0) < 10 then 'low_product_usage'
        when coalesce(avg_csat_score, 5) < 3.5 then 'low_csat'
        when coalesce(avg_resolution_hours, 0) > 48 then 'slow_support'
        when coalesce(seat_utilization_pct, 0) < 0.20 then 'low_seat_utilization'
        else 'healthy'
    end as primary_risk_reason
from {{ ref('int_account_monthly') }}