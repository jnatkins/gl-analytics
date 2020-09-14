/* grain: one record per subscription per month */
WITH dim_dates AS (

    SELECT *
    FROM {{ ref('dim_dates') }}

), zuora_account AS (

  SELECT *
  FROM {{ ref('zuora_account_source') }}

), zuora_rate_plan AS (

  SELECT *
  FROM {{ ref('zuora_rate_plan_source') }}

), zuora_rate_plan_charge AS (

  SELECT *
  FROM {{ ref('zuora_rate_plan_charge_source') }}
  WHERE charge_type = 'Recurring'
    AND mrr != 0 /* This excludes Education customers (charge name EDU or OSS) with free subscriptions */

), zuora_subscription AS (

  SELECT *
  FROM {{ ref('zuora_subscription_source') }}

), zuora_subscription_snapshots AS (

  /**
  This partition handles duplicates and hard deletes by taking only
    the latest subscription version snapshot
   */

  SELECT
    rank() OVER (
      PARTITION BY subscription_name
      ORDER BY DBT_VALID_FROM DESC) AS rank,
    subscription_id
  FROM {{ ref('zuora_subscription_snapshots_source') }}
  WHERE subscription_status NOT IN ('Draft', 'Expired')
    AND CURRENT_TIMESTAMP()::TIMESTAMP_TZ >= dbt_valid_from
    AND {{ coalesce_to_infinity('dbt_valid_to') }} > current_timestamp()::TIMESTAMP_TZ

), rate_plan_charge_filtered AS (

  SELECT
    zuora_account.account_id,
    zuora_account.crm_id,
    zuora_subscription_snapshots.subscription_id,
    zuora_rate_plan_charge.product_rate_plan_charge_id AS product_details_id,
    zuora_rate_plan_charge.mrr,
    zuora_rate_plan_charge.delta_tcv,
    zuora_rate_plan_charge.unit_of_measure,
    zuora_rate_plan_charge.quantity,
    zuora_rate_plan_charge.effective_start_month,
    zuora_rate_plan_charge.effective_end_month
  FROM zuora_rate_plan_charge
  INNER JOIN zuora_rate_plan
    ON zuora_rate_plan.rate_plan_id = zuora_rate_plan_charge.rate_plan_id
  INNER JOIN zuora_subscription
    ON zuora_rate_plan.subscription_id = zuora_subscription.subscription_id
  INNER JOIN zuora_subscription_snapshots
    ON zuora_subscription_snapshots.subscription_id = zuora_subscription.subscription_id
    AND zuora_subscription_snapshots.rank = 1
  INNER JOIN zuora_account
    ON zuora_account.account_id = zuora_subscription.account_id
  WHERE zuora_subscription.is_deleted = FALSE
    AND zuora_subscription.exclude_from_analysis IN ('False', '')
    AND zuora_account.is_deleted = FALSE

), mrr_month_by_month AS (

  SELECT
    dim_dates.date_id,
    account_id,
    crm_id,
    subscription_id,
    product_details_id,
    SUM(mrr) AS mrr,
    SUM(mrr)* 12 AS arr,
    SUM(quantity) AS quantity
  FROM rate_plan_charge_filtered
  INNER JOIN dim_dates
    ON rate_plan_charge_filtered.effective_start_month <= dim_dates.date_actual
    AND (rate_plan_charge_filtered.effective_end_month > dim_dates.date_actual
      OR rate_plan_charge_filtered.effective_end_month IS NULL)
    AND dim_dates.day_of_month = 1
  {{ dbt_utils.group_by(n=5) }}

)

SELECT
  {{ dbt_utils.surrogate_key(['date_id', 'subscription_id', 'product_details_id']) }}
    AS mrr_id,
  *
FROM mrr_month_by_month




