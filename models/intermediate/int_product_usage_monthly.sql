select
    event_month as month_start,
    account_id,
    account_id || '|' || to_varchar(event_month, 'YYYY-MM-DD') as account_month_key,
    count(*) as total_events,
    count(distinct user_id) as active_users_in_month,
    sum(case when event_family = 'workflow_automation' then 1 else 0 end) as workflow_automation_events,
    sum(case when event_family = 'dashboard' then 1 else 0 end) as dashboard_events,
    sum(case when event_family = 'collaboration' then 1 else 0 end) as collaboration_events,
    sum(case when event_family = 'authentication' then 1 else 0 end) as authentication_events,
    sum(case when event_family = 'core_usage' then 1 else 0 end) as core_usage_events,
    sum(case when feature_adopted_flag then 1 else 0 end) as feature_adoption_events,
    max(event_ts) as last_event_ts
from {{ ref('stg_product_events') }}
group by 1, 2, 3