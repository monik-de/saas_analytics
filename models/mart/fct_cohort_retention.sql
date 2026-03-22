with cohorts as (
    select
        signup_month as cohort_month,
        count(distinct account_id) as cohort_size
    from {{ ref('stg_accounts') }}
    group by 1
),

month_numbers as (
    select seq4() as months_since_signup
    from table(generator(rowcount => 36))
),

cohort_spine as (
    select
        cohorts.cohort_month,
        month_numbers.months_since_signup,
        dateadd('month', month_numbers.months_since_signup, cohorts.cohort_month)::date as activity_month,
        cohorts.cohort_size
    from cohorts
    cross join month_numbers
),

retained as (
    select
        stg_accounts.signup_month as cohort_month,
        int_account_monthly.months_since_signup,
        count(distinct int_account_monthly.account_id) as retained_accounts,
        sum(int_account_monthly.mrr) as retained_mrr,
        avg(int_account_monthly.health_score) as avg_health_score
    from {{ ref('int_account_monthly') }} as int_account_monthly
    inner join {{ ref('stg_accounts') }} as stg_accounts
        on int_account_monthly.account_id = stg_accounts.account_id
    where int_account_monthly.is_active_subscription
      and int_account_monthly.months_since_signup between 0 and 35
    group by 1, 2
),

base as (
    select
        cohort_spine.cohort_month,
        cohort_spine.activity_month,
        cohort_spine.months_since_signup,
        cohort_spine.cohort_size,
        coalesce(retained.retained_accounts, 0) as retained_accounts,
        coalesce(retained.retained_mrr, 0) as retained_mrr,
        retained.avg_health_score
    from cohort_spine
    left join retained
        on cohort_spine.cohort_month = retained.cohort_month
       and cohort_spine.months_since_signup = retained.months_since_signup
    where cohort_spine.activity_month <= (
        select max(month_start) from {{ ref('int_account_monthly') }}
    )
),

with_start_mrr as (
    select
        *,
        max(case when months_since_signup = 0 then retained_mrr end)
            over (partition by cohort_month) as cohort_start_mrr
    from base
)

select
    to_varchar(cohort_month, 'YYYY-MM-DD') || '|' || months_since_signup as cohort_month_number_key,
    cohort_month,
    activity_month,
    months_since_signup,
    cohort_size,
    retained_accounts,
    round(retained_accounts / nullif(cohort_size, 0), 4) as logo_retention_rate,
    retained_mrr,
    cohort_start_mrr,
    round(retained_mrr / nullif(cohort_start_mrr, 0), 4) as revenue_retention_rate,
    avg_health_score
from with_start_mrr
order by cohort_month, months_since_signup