select
    event_id,
    event_ts,
    to_date(event_ts) as event_date,
    date_trunc('month', event_ts)::date as event_month,
    account_id,
    user_id,
    lower(event_name) as event_name,
    lower(plan) as plan_name,
    iff(feature_adopted = 1, true, false) as feature_adopted_flag,
    region,
    case
        when lower(event_name) like '%workflow_automation%' then 'workflow_automation'
        when lower(event_name) like '%dashboard%' then 'dashboard'
        when lower(event_name) like '%invite%' then 'collaboration'
        when lower(event_name) like '%login%' then 'authentication'
        else 'core_usage'
    end as event_family
from {{ source('raw', 'product_events') }}