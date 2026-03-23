with month_spine as (
    select distinct signup_month as month_start from {{ ref('stg_accounts') }}
    union
    select distinct month_start from {{ ref('int_account_monthly') }}
    union
    select distinct month_start from {{ ref('int_revenue_movements_monthly') }}
),

ending_snapshot as (
    select
        month_start,
        count(distinct account_id) as active_accounts,
        sum(mrr) as ending_mrr
    from {{ ref('int_account_monthly') }}
    where is_active_subscription
    group by 1
),

revenue as (
    select
        month_start,
        sum(new_mrr) as new_mrr,
        sum(reactivation_mrr) as reactivation_mrr,
        sum(expansion_mrr) as expansion_mrr,
        sum(contraction_mrr) as contraction_mrr,
        sum(churned_mrr) as churned_mrr,
        sum(net_new_mrr) as net_new_mrr,
        count(distinct case when churned_mrr > 0 then account_id end) as churned_accounts
    from {{ ref('int_revenue_movements_monthly') }}
    group by 1
),

conversions as (
    select
        date_trunc('month', converted_to_paid_at)::date as month_start,
        count(distinct account_id) as new_paid_accounts
    from {{ ref('stg_accounts') }}
    where converted_to_paid_at is not null
    group by 1
),

assembled as (
    select
        month_spine.month_start,
        coalesce(ending_snapshot.active_accounts, 0) as active_accounts,
        coalesce(ending_snapshot.ending_mrr, 0) as ending_mrr,
        coalesce(revenue.new_mrr, 0) as new_mrr,
        coalesce(revenue.reactivation_mrr, 0) as reactivation_mrr,
        coalesce(revenue.expansion_mrr, 0) as expansion_mrr,
        coalesce(revenue.contraction_mrr, 0) as contraction_mrr,
        coalesce(revenue.churned_mrr, 0) as churned_mrr,
        coalesce(revenue.net_new_mrr, 0) as net_new_mrr,
        coalesce(revenue.churned_accounts, 0) as churned_accounts,
        coalesce(conversions.new_paid_accounts, 0) as new_paid_accounts
    from month_spine
    left join ending_snapshot
        on month_spine.month_start = ending_snapshot.month_start
    left join revenue
        on month_spine.month_start = revenue.month_start
    left join conversions
        on month_spine.month_start = conversions.month_start
),

final as (
    select
        month_start,
        active_accounts,
        lag(active_accounts) over (order by month_start) as previous_active_accounts,
        lag(ending_mrr) over (order by month_start) as starting_mrr,
        ending_mrr,
        new_mrr,
        reactivation_mrr,
        expansion_mrr,
        contraction_mrr,
        churned_mrr,
        net_new_mrr,
        new_paid_accounts,
        churned_accounts
    from assembled
)

select
    month_start,
    coalesce(previous_active_accounts, 0) as previous_active_accounts,
    coalesce(starting_mrr, 0) as starting_mrr,
    ending_mrr,
    active_accounts,
    new_mrr,
    reactivation_mrr,
    expansion_mrr,
    contraction_mrr,
    churned_mrr,
    net_new_mrr,
    new_paid_accounts,
    churned_accounts,
    ending_mrr - coalesce(starting_mrr, 0) as ending_mrr_change,
    round(churned_accounts / nullif(previous_active_accounts, 0), 4) as logo_churn_rate,
    round((starting_mrr - contraction_mrr - churned_mrr) / nullif(starting_mrr, 0), 4) as grr,
    round((starting_mrr + expansion_mrr - contraction_mrr - churned_mrr) / nullif(starting_mrr, 0), 4) as nrr
from final
order by month_start