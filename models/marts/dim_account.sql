with latest_account_month as (
    select
        *,
        row_number() over (
            partition by account_id
            order by month_start desc
        ) as rn
    from {{ ref('int_account_monthly') }}
),

user_stats as (
    select
        account_id,
        count(*) as total_users,
        sum(case when is_admin then 1 else 0 end) as admin_users
    from {{ ref('stg_users') }}
    group by 1
),

invoice_stats as (
    select
        account_id,
        count(*) as total_invoices,
        sum(invoice_amount) as lifetime_billed_amount,
        sum(case when is_paid then invoice_amount else 0 end) as lifetime_paid_amount
    from {{ ref('stg_invoices') }}
    group by 1
),

support_stats as (
    select
        account_id,
        count(*) as total_tickets,
        avg(csat_score) as lifetime_avg_csat_score
    from {{ ref('stg_support_tickets') }}
    group by 1
)

select
    accounts.account_id,
    accounts.company_name,
    accounts.signup_date,
    accounts.signup_month,
    accounts.activated_at,
    accounts.converted_to_paid_at,
    accounts.segment,
    accounts.acquisition_channel,
    accounts.region,
    accounts.industry,
    accounts.initial_plan,
    accounts.billing_period as initial_billing_period,
    accounts.initial_paid_seats,
    accounts.seat_capacity,
    accounts.user_capacity,
    accounts.activation_score,
    accounts.is_activated,
    accounts.is_paid_converted,
    accounts.started_annual,
    accounts.days_signup_to_activation,
    accounts.days_trial_to_paid,

    coalesce(user_stats.total_users, 0) as total_users,
    coalesce(user_stats.admin_users, 0) as admin_users,

    coalesce(invoice_stats.total_invoices, 0) as total_invoices,
    coalesce(invoice_stats.lifetime_billed_amount, 0) as lifetime_billed_amount,
    coalesce(invoice_stats.lifetime_paid_amount, 0) as lifetime_paid_amount,

    coalesce(support_stats.total_tickets, 0) as total_tickets,
    support_stats.lifetime_avg_csat_score,

    latest_account_month.month_start as last_active_month,
    latest_account_month.plan_name as current_plan_name,
    latest_account_month.billing_period as current_billing_period,
    latest_account_month.mrr as current_mrr,
    latest_account_month.health_score as current_health_score,
    latest_account_month.health_bucket as current_health_bucket,
    latest_account_month.is_active_subscription as is_currently_active,
    latest_account_month.at_risk_flag as is_currently_at_risk

from {{ ref('stg_accounts') }} as accounts
left join latest_account_month
    on accounts.account_id = latest_account_month.account_id
   and latest_account_month.rn = 1
left join user_stats
    on accounts.account_id = user_stats.account_id
left join invoice_stats
    on accounts.account_id = invoice_stats.account_id
left join support_stats
    on accounts.account_id = support_stats.account_id