select
    ticket_id,
    account_id,
    opened_at,
    to_date(opened_at) as opened_date,
    date_trunc('month', opened_at)::date as opened_month,
    lower(category) as category,
    lower(priority) as priority,
    resolution_hours,
    round(resolution_hours / 24, 2) as resolution_days,
    csat_score,
    iff(resolution_hours <= 24, true, false) as resolved_within_24h
from {{ source('raw', 'support_tickets') }}