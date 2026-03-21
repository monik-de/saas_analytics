select
    invoice_id,
    account_id,
    invoice_date,
    to_date(invoice_date) as invoice_day,
    date_trunc('month', invoice_date)::date as invoice_month,
    lower(billing_period) as billing_period,
    lower(plan) as plan_name,
    invoice_amount,
    mrr_equivalent,
    lower(paid_status) as paid_status,
    iff(lower(paid_status) = 'paid', true, false) as is_paid
from {{ source('raw', 'invoices') }}