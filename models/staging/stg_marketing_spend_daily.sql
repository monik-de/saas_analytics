select
    spend_date,
    date_trunc('month', spend_date)::date as spend_month,
    lower(channel) as channel,
    spend_usd
from {{ source('raw', 'marketing_spend_daily') }}