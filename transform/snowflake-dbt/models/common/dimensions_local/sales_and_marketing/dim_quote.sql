{{ config(
    tags=["mnpi_exception"]
) }}

WITH quote AS (

    SELECT
      dim_quote_id,
      quote_number,
      quote_name,
      quote_status,
      quote_entity,
      is_primary_quote,
      quote_start_date
    FROM {{ ref('prep_quote') }}

)

{{ dbt_audit(
    cte_ref="quote",
    created_by="@snalamaru",
    updated_by="@chrissharp",
    created_date="2021-01-07",
    updated_date="2022-10-04"
) }}
