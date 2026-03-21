with monthly as (
    select
        event_month as month_start,
        account_id,
        account_id || '|' || to_varchar(event_month, 'YYYY-MM-DD') as account_month_key,

        sum(
            case
                when revenue_event_type = 'new_business'
                then coalesce(nullif(mrr_after, 0), greatest(coalesce(mrr_delta, 0), 0), 0)
                else 0
            end
        ) as new_mrr,

        sum(
            case
                when revenue_event_type = 'reactivation'
                then coalesce(nullif(mrr_after, 0), greatest(coalesce(mrr_delta, 0), 0), 0)
                else 0
            end
        ) as reactivation_mrr,

        sum(
            case
                when revenue_event_type = 'expansion'
                then greatest(coalesce(mrr_delta, 0), 0)
                else 0
            end
        ) as expansion_mrr,

        sum(
            case
                when revenue_event_type = 'contraction'
                then abs(least(coalesce(mrr_delta, 0), 0))
                else 0
            end
        ) as contraction_mrr,

        sum(
            case
                when revenue_event_type = 'churn'
                then coalesce(nullif(mrr_before, 0), abs(coalesce(mrr_delta, 0)), 0)
                else 0
            end
        ) as churned_mrr,

        count(*) as revenue_event_count,
        count_if(revenue_event_type = 'churn') as churn_event_count,
        count_if(revenue_event_type = 'expansion') as expansion_event_count
    from {{ ref('stg_subscription_events') }}
    group by 1, 2, 3
)

select
    *,
    new_mrr + reactivation_mrr + expansion_mrr - contraction_mrr - churned_mrr as net_new_mrr
from monthly