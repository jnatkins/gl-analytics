{{ config({
    "materialized": "table"
    })
}}


WITH licenses AS (
 
  SELECT *
  FROM {{ ref('customers_db_licenses_source') }}
  WHERE (license_md5 IS NOT NULL OR
         license_sha256 IS NOT NULL)
    AND is_trial = False
    -- Remove internal test licenses
    AND NOT (email LIKE '%@gitlab.com' AND LOWER(company) LIKE '%gitlab%')
    
), usage_data AS (

  SELECT id,
         license_md5,
         license_sha256,
         created_at
  FROM {{ ref('version_usage_data_unpacked') }}
  WHERE license_md5 IS NOT NULL OR
        license_sha256 IS NOT NULL

), usage_data_md5 AS (

  SELECT id,
         license_md5,
         created_at
  FROM usage_data
  WHERE license_md5 IS NOT NULL

), usage_data_sha256 AS (

  SELECT id,
         license_sha256,
         created_at
  FROM usage_data
  WHERE license_sha256 IS NOT NULL

),week_spine AS (

  SELECT DISTINCT
    DATE_TRUNC('week', date_actual) AS week
  FROM {{ ref('date_details') }}
  WHERE date_details.date_actual BETWEEN '2017-04-01' AND CURRENT_DATE

), grouped AS (

  SELECT
    week_spine.week,
    licenses.license_id,
    licenses.license_md5,
    licenses.license_sha256,
    licenses.zuora_subscription_id,
    licenses.plan_code                                           AS product_category,
    MAX(IFF(COALESCE(usage_data_md5.id, usage_data_sha256.id) IS NOT NULL, 1, 0)) AS did_send_usage_data,
    COUNT(DISTINCT COALESCE(usage_data_md5.id, usage_data_sha256.id))             AS count_usage_data_pings,
    MIN(COALESCE(usage_data_md5.created_at, usage_data_sha256.created_at))        AS min_usage_data_created_at,
    MAX(COALESCE(usage_data_md5.created_at, usage_data_sha256.created_at))        AS max_usage_data_created_at
  FROM week_spine
    LEFT JOIN licenses
      ON week_spine.week BETWEEN licenses.license_start_date AND {{ coalesce_to_infinity("licenses.license_expire_date") }}
    LEFT JOIN usage_data_md5
      ON licenses.license_md5 = usage_data_md5.license_md5
      AND week_spine.week = DATE_TRUNC('week', usage_data_md5.created_at)
    LEFT JOIN usage_data_sha256
      ON licenses.license_sha256 = usage_data_sha256.license_sha256
      AND week_spine.week = DATE_TRUNC('week', usage_data_sha256.created_at)
  {{ dbt_utils.group_by(n=6) }}

), alphabetized AS (

    SELECT
      week,
      license_id,
      license_md5,
      license_sha256,
      product_category,
      zuora_subscription_id,

      --metadata
      count_usage_data_pings,
      did_send_usage_data::BOOLEAN AS did_send_usage_data,
      min_usage_data_created_at,
      max_usage_data_created_at
    FROM grouped

)

SELECT *
FROM alphabetized
