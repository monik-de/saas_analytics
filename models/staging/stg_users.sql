select
    user_id,
    account_id,
    user_created_at,
    to_date(user_created_at) as user_created_date,
    date_trunc('month', user_created_at)::date as user_created_month,
    role as user_role,
    lower(department) as department,
    job_title,
    is_admin
from {{ source('raw', 'users') }}