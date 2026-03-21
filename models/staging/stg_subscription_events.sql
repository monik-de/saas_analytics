select
    account_id,
    event_at,
    to_date(event_at) as event_date,
    date_trunc('month', event_at)::date as event_month,
    lower(event_type) as event_type,
    lower(plan_before) as plan_before,
    lower(plan_after) as plan_after,
    seats_before,
    seats_after,
    mrr_before,
    mrr_after,
    mrr_delta,
    case
        when lower(event_type) in ('new', 'new_business') then 'new_business'
        when lower(event_type) in ('reactivation') then 'reactivation'
        when lower(event_type) in ('expansion') or mrr_delta > 0 then 'expansion'
        when lower(event_type) in ('contraction') or mrr_delta < 0 then 'contraction'
        when lower(event_type) in ('churn', 'cancellation', 'cancelled') or (mrr_after = 0 and mrr_before > 0) then 'churn'
        else 'other'
    end as revenue_event_type
from {{ source('raw', 'subscription_events') }}