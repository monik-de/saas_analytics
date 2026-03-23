with spend as (
    select
        spend_month as month_start,
        channel,
        sum(spend_usd) as spend_usd
    from {{ ref('stg_marketing_spend_daily') }}
    group by 1, 2
),

signup_cohorts as (
    select
        signup_month as month_start,
        acquisition_channel as channel,
        count(*) as signups,
        count_if(is_activated) as activated_accounts,
        count_if(is_paid_converted) as paid_conversions,
        count_if(started_annual) as annual_starts,
        avg(activation_score) as avg_activation_score,
        avg(days_signup_to_activation) as avg_days_signup_to_activation,
        avg(days_trial_to_paid) as avg_days_trial_to_paid
    from {{ ref('stg_accounts') }}
    group by 1, 2
),

month_channel_spine as (
    select month_start, channel from spend
    union
    select month_start, channel from signup_cohorts
),

assembled as (
    select
        to_varchar(month_channel_spine.month_start, 'YYYY-MM-DD') || '|' || month_channel_spine.channel as month_channel_key,
        month_channel_spine.month_start,
        month_channel_spine.channel,
        coalesce(spend.spend_usd, 0) as spend_usd,
        coalesce(signup_cohorts.signups, 0) as signups,
        coalesce(signup_cohorts.activated_accounts, 0) as activated_accounts,
        coalesce(signup_cohorts.paid_conversions, 0) as paid_conversions,
        coalesce(signup_cohorts.annual_starts, 0) as annual_starts,
        signup_cohorts.avg_activation_score,
        signup_cohorts.avg_days_signup_to_activation,
        signup_cohorts.avg_days_trial_to_paid
    from month_channel_spine
    left join spend
        on month_channel_spine.month_start = spend.month_start
       and month_channel_spine.channel = spend.channel
    left join signup_cohorts
        on month_channel_spine.month_start = signup_cohorts.month_start
       and month_channel_spine.channel = signup_cohorts.channel
)

select
    month_channel_key,
    month_start,
    channel,
    spend_usd,
    signups,
    activated_accounts,
    paid_conversions,
    annual_starts,
    avg_activation_score,
    avg_days_signup_to_activation,
    avg_days_trial_to_paid,
    round(activated_accounts / nullif(signups, 0), 4) as activation_rate,
    round(paid_conversions / nullif(signups, 0), 4) as trial_to_paid_rate,
    round(spend_usd / nullif(signups, 0), 2) as cost_per_signup,
    round(spend_usd / nullif(paid_conversions, 0), 2) as cac_per_paid_account
from assembled
order by month_start, channel