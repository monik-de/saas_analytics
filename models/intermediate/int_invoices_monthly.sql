select
    invoice_month as month_start,
    account_id,
    account_id || '|' || to_varchar(invoice_month, 'YYYY-MM-DD') as account_month_key,
    count(*) as invoice_count,
    sum(case when is_paid then 1 else 0 end) as paid_invoice_count,
    sum(invoice_amount) as billed_amount,
    sum(case when is_paid then invoice_amount else 0 end) as paid_invoice_amount,
    sum(mrr_equivalent) as mrr_equivalent_billed,
    sum(case when is_paid then mrr_equivalent else 0 end) as mrr_equivalent_paid,
    avg(invoice_amount) as avg_invoice_amount,
    sum(case when is_paid then 1 else 0 end) / nullif(count(*), 0) as collection_rate
from {{ ref('stg_invoices') }}
group by 1, 2, 3