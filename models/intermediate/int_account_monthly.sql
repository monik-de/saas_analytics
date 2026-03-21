with snapshot as (
    select * from {{ ref('stg_subscription_monthly_snapshot') }}
),

accounts as (
    select * from {{ ref('stg_accounts') }}
),

usage as (
    select * from {{ ref('int_product_usage_monthly') }}
),

support as (
    select * from {{ ref('int_support_monthly') }}
),

invoices as (
    select * from {{ ref('int_invoices_monthly') }}
),

revenue as (
    select * from {{ ref('int_revenue_movements_monthly') }}
)

select
    snapshot.account_id || '|' || to_varchar(snapshot.month_start, 'YYYY-MM-DD') as account_month_key,
    snapshot.month_start,
    snapshot.account_id,
    accounts.company_name,
    accounts.signup_date,
    accounts.signup_month,
    datediff('month', accounts.signup_month, snapshot.month_start) as months_since_signup,
    coalesce(snapshot.segment, accounts.segment) as segment,
    coalesce(snapshot.acquisition_channel, accounts.acquisition_channel) as acquisition_channel,
    coalesce(snapshot.region, accounts.region) as region,
    accounts.industry,
    snapshot.plan_name,
    snapshot.billing_period,
    snapshot.mrr,
    snapshot.active_seats,
    snapshot.user_capacity,
    snapshot.seat_utilization_pct,
    snapshot.usage_multiplier,
    snapshot.health_score,
    snapshot.is_active_subscription,
    snapshot.has_adopted_key_feature,

    coalesce(usage.total_events, 0) as total_events,
    coalesce(usage.active_users_in_month, 0) as active_users_in_month,
    coalesce(usage.workflow_automation_events, 0) as workflow_automation_events,
    coalesce(usage.dashboard_events, 0) as dashboard_events,
    coalesce(usage.collaboration_events, 0) as collaboration_events,
    coalesce(usage.authentication_events, 0) as authentication_events,
    coalesce(usage.core_usage_events, 0) as core_usage_events,
    coalesce(usage.feature_adoption_events, 0) as feature_adoption_events,

    coalesce(support.ticket_count, 0) as ticket_count,
    support.avg_resolution_hours,
    support.avg_resolution_days,
    support.pct_resolved_within_24h,
    support.avg_csat_score,

    coalesce(invoices.invoice_count, 0) as invoice_count,
    coalesce(invoices.paid_invoice_count, 0) as paid_invoice_count,
    coalesce(invoices.billed_amount, 0) as billed_amount,
    coalesce(invoices.paid_invoice_amount, 0) as paid_invoice_amount,
    invoices.collection_rate,

    coalesce(revenue.new_mrr, 0) as new_mrr,
    coalesce(revenue.reactivation_mrr, 0) as reactivation_mrr,
    coalesce(revenue.expansion_mrr, 0) as expansion_mrr,
    coalesce(revenue.contraction_mrr, 0) as contraction_mrr,
    coalesce(revenue.churned_mrr, 0) as churned_mrr,
    coalesce(revenue.net_new_mrr, 0) as net_new_mrr,

    case
        when snapshot.health_score >= 80 then 'champion'
        when snapshot.health_score >= 60 then 'healthy'
        when snapshot.health_score >= 40 then 'monitor'
        else 'at_risk'
    end as health_bucket,

    case
        when snapshot.health_score < 40
          or coalesce(usage.total_events, 0) < 10
          or coalesce(support.avg_csat_score, 5) < 3.5
          or coalesce(support.avg_resolution_hours, 0) > 48
          or coalesce(snapshot.seat_utilization_pct, 0) < 0.20
        then true else false
    end as at_risk_flag,

    case
        when snapshot.health_score >= 80
         and coalesce(usage.workflow_automation_events, 0) >= 5
         and coalesce(snapshot.seat_utilization_pct, 0) >= 0.65
        then true else false
    end as expansion_candidate_flag

from snapshot
left join accounts
    on snapshot.account_id = accounts.account_id
left join usage
    on snapshot.account_id = usage.account_id
   and snapshot.month_start = usage.month_start
left join support
    on snapshot.account_id = support.account_id
   and snapshot.month_start = support.month_start
left join invoices
    on snapshot.account_id = invoices.account_id
   and snapshot.month_start = invoices.month_start
left join revenue
    on snapshot.account_id = revenue.account_id
   and snapshot.month_start = revenue.month_start