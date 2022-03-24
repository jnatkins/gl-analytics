{{ config({
    "alias": "fct_mrr",
    "post-hook": '{{ apply_dynamic_data_masking(columns = [{"arr":"float"},{"dim_charge_id":"string"},{"dim_product_detail_id":"string"},{"created_by":"string"},{"dim_billing_account_id":"string"},{"dim_crm_account_id":"string"},{"dim_subscription_id":"string"},{"mrr":"float"},{"mrr_id":"string"},{"updated_by":"string"}]) }}'
}) }}

/* grain: one record per rate_plan_charge per month */

{{ simple_cte([
    ('dim_date', 'dim_date'),
    ('prep_charge', 'prep_charge')
]) }}

, mrr AS (

    SELECT
      {{ dbt_utils.surrogate_key(['dim_date.date_id','prep_charge.dim_charge_id']) }}       AS mrr_id,
      dim_date.date_id                                                                      AS dim_date_id,
      prep_charge.dim_charge_id,
      prep_charge.dim_product_detail_id,
      prep_charge.dim_subscription_id,
      prep_charge.dim_billing_account_id,
      prep_charge.dim_crm_account_id,
      prep_charge.subscription_status,
      SUM(prep_charge.mrr)                                                                  AS mrr,
      SUM(prep_charge.mrr) * 12                                                             AS arr,
      SUM(prep_charge.quantity)                                                             AS quantity,
      ARRAY_AGG(prep_charge.unit_of_measure)                                                AS unit_of_measure
    FROM prep_charge
    INNER JOIN dim_date
      ON prep_charge.effective_start_month <= dim_date.date_actual
      AND (prep_charge.effective_end_month > dim_date.date_actual
        OR prep_charge.effective_end_month IS NULL)
      AND dim_date.day_of_month = 1
    WHERE subscription_status NOT IN ('Draft')
      AND charge_type = 'Recurring'
      /* This excludes Education customers (charge name EDU or OSS) with free subscriptions.
         Pull in seats from Paid EDU Plans with no ARR */
      AND (mrr != 0 OR LOWER(prep_charge.rate_plan_charge_name) = 'max enrollment')
    {{ dbt_utils.group_by(n=8) }}
)

{{ dbt_audit(
    cte_ref="mrr",
    created_by="@msendal",
    updated_by="@iweeks",
    created_date="2020-09-10",
    updated_date="2022-03-24",
) }}
