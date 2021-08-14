{{config({
    "schema": "common_mart_sales"
  })
}}

{{ simple_cte([
    ('driveload_financial_metrics_program_phase_1','driveload_financial_metrics_program_phase_1'),
    ('dim_date','dim_date'),
    ('mart_arr_snapshot_model','mart_arr_snapshot_model'),
    ('dim_crm_account','dim_crm_account'),
    ('zuora_account_source','zuora_account_source')
]) }}

, phase_one AS (

    SELECT
      arr_month,
      fiscal_quarter_name_fy,
      fiscal_year,
      subscription_start_month,
      subscription_end_month,
      zuora_account_id                          AS dim_billing_account_name,
      zuora_sold_to_country                     AS sold_to_country,
      zuora_account_name                        AS billing_account_name,
      zuora_account_number                      AS billing_account_number,
      dim_crm_account_id,
      dim_parent_crm_account_id,
      parent_crm_account_name,
      parent_crm_account_billing_country,
      parent_crm_account_sales_segment,
      parent_crm_account_industry,
      parent_crm_account_owner_team,
      parent_crm_account_sales_territory,
      subscription_name,
      subscription_status,
      subscription_sales_type,
      product_category                          AS product_tier_name,
      delivery                                  AS product_delivery_type,
      service_type,
      unit_of_measure,
      mrr,
      arr,
      quantity,
      parent_account_cohort_month,
      months_since_parent_account_cohort_start
    FROM driveload_financial_metrics_program_phase_1
    WHERE arr_month <= '2021-05-01'

), snapshot_dates AS (
    --Use the 8th calendar day to snapshot ARR, Licensed Users, and Customer Count Metrics
    SELECT DISTINCT
      first_day_of_month,
      snapshot_date_fpa
    FROM common.dim_date
    ORDER BY 1 DESC

), parent_cohort_month_snapshot AS (

    SELECT
      dim_parent_crm_account_id,
      MIN(arr_month)                                            AS parent_account_cohort_month
    FROM mart_arr_snapshot_model
    {{ dbt_utils.group_by(n=1) }}

), snapshot_model AS (

    SELECT
      mart_arr_snapshot_model.arr_month,
      mart_arr_snapshot_model.fiscal_quarter_name_fy,
      mart_arr_snapshot_model.fiscal_year,
      mart_arr_snapshot_model.subscription_start_month,
      mart_arr_snapshot_model.subscription_end_month,
      mart_arr_snapshot_model.dim_billing_account_id,
      mart_arr_snapshot_model.sold_to_country,
      mart_arr_snapshot_model.billing_account_name,
      mart_arr_snapshot_model.billing_account_number,
      mart_arr_snapshot_model.dim_crm_account_id,
      mart_arr_snapshot_model.dim_parent_crm_account_id,
      mart_arr_snapshot_model.parent_crm_account_name,
      mart_arr_snapshot_model.parent_crm_account_billing_country,
      mart_arr_snapshot_model.parent_crm_account_sales_segment,
      mart_arr_snapshot_model.parent_crm_account_industry,
      mart_arr_snapshot_model.parent_crm_account_owner_team,
      mart_arr_snapshot_model.parent_crm_account_sales_territory,
      mart_arr_snapshot_model.subscription_name,
      mart_arr_snapshot_model.subscription_status,
      mart_arr_snapshot_model.subscription_sales_type,
      mart_arr_snapshot_model.product_tier_name,
      mart_arr_snapshot_model.product_delivery_type,
      mart_arr_snapshot_model.service_type,
      mart_arr_snapshot_model.unit_of_measure,
      mart_arr_snapshot_model.mrr,
      mart_arr_snapshot_model.arr,
      mart_arr_snapshot_model.quantity,
      parent_cohort_month_snapshot.parent_account_cohort_month                                  AS parent_account_cohort_month,
      DATEDIFF(month, parent_cohort_month_snapshot.parent_account_cohort_month, arr_month)      AS months_since_parent_account_cohort_start
    FROM mart_arr_snapshot_model
    INNER JOIN snapshot_dates
      ON mart_arr_snapshot_model.arr_month = snapshot_dates.first_day_of_month
      AND mart_arr_snapshot_model.snapshot_date = snapshot_dates.snapshot_date_fpa
    --filter out test accounts. Historical records in this model have the test accounts, so need to filter out here
    LEFT JOIN zuora_account_source
      ON mart_arr_snapshot_model.dim_billing_account_id = zuora_account_source.account_id
    --filter out JiHu accounts based on correct JiHu flag logic
    LEFT JOIN dim_crm_account
      ON mart_arr_snapshot_model.dim_crm_account_id = dim_crm_account.dim_crm_account_id
    --calculate parent cohort month based on correct cohort logic
    LEFT JOIN parent_cohort_month_snapshot
      ON mart_arr_snapshot_model.dim_parent_crm_account_id = parent_cohort_month_snapshot.dim_parent_crm_account_id
    WHERE LOWER(zuora_account_source.batch) != 'batch20'
      AND dim_crm_account.is_jihu_account = 'FALSE'
      AND mart_arr_snapshot_model.arr_month >= '2021-06-01'
    ORDER BY 1 DESC

), combined AS (

    SELECT *
    FROM snapshot_model

    UNION ALL

    SELECT *
    FROM phase_one

), parent_arr AS (

    SELECT
      arr_month,
      dim_parent_crm_account_id,
      SUM(arr)                                   AS arr
    FROM combined
    GROUP BY 1,2

), parent_arr_band_calc AS (

    SELECT
      arr_month,
      dim_parent_crm_account_id,
      CASE
        WHEN arr > 5000 THEN 'ARR > $5K'
        WHEN arr <= 5000 THEN 'ARR <= $5K'
      END                                        AS arr_band_calc
    FROM parent_arr

), final AS (
    --Snap in arr_band_calc based on correct logic. Some historical in mart_arr_snapshot_model do not have the arr_band_calc.
    SELECT
      combined.*,
      parent_arr_band_calc.arr_band_calc
    FROM combined
    LEFT JOIN parent_arr_band_calc
      ON combined.dim_parent_crm_account_id = parent_arr_band_calc.dim_parent_crm_account_id
      AND combined.arr_month = parent_arr_band_calc.arr_month

)

{{ dbt_audit(
    cte_ref="final",
    created_by="@iweeks",
    updated_by="@iweeks",
    created_date="2021-08-16",
    updated_date="2021-08-16"
) }}
