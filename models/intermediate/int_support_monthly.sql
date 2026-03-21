select
    opened_month as month_start,
    account_id,
    account_id || '|' || to_varchar(opened_month, 'YYYY-MM-DD') as account_month_key,
    count(*) as ticket_count,
    sum(case when priority = 'high' then 1 else 0 end) as high_priority_tickets,
    sum(case when category = 'bug' then 1 else 0 end) as bug_tickets,
    avg(resolution_hours) as avg_resolution_hours,
    avg(resolution_days) as avg_resolution_days,
    avg(case when resolved_within_24h then 1.0 else 0.0 end) as pct_resolved_within_24h,
    avg(csat_score) as avg_csat_score
from {{ ref('stg_support_tickets') }}
group by 1, 2, 3