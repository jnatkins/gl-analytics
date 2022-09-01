{{ config({
    "materialized":"table",
    "schema": "legacy",
    "database": env_var('SNOWFLAKE_PROD_DATABASE'),
    })
}}

WITH employee_directory_intermediate AS (

  SELECT team_member.*, manager.employee_id AS reports_to_id 
  FROM {{ ref('employee_directory_intermediate') }} AS team_member, {{ ref('employee_directory_intermediate') }} AS manager
  WHERE team_member.reports_to = manager.full_name
),

cleaned AS (

  SELECT
    date_actual,
    employee_id,
    reports_to,
    reports_to_id,
    full_name,
    work_email,
    gitlab_username,
    CASE
        WHEN region = 'Americas' AND country IN ('United States', 'Canada','Mexico','United States of America') 
          THEN 'NORAM'
        WHEN region = 'Americas' AND country NOT IN ('United States', 'Canada','Mexico','United States of America') 
          THEN 'LATAM'
        ELSE region 
    END AS region_modified,
    sales_geo_differential,
    jobtitle_speciality,
    job_role_modified,
    is_hire_date,
    is_termination_date,
    hire_date,
    cost_center,
    layers,
    job_title,
    COALESCE(location_factor, hire_location_factor) AS location_factor,
    CASE --the below case when statement is also used in bamboohr_job_info;
      WHEN division = 'Alliances' THEN 'Alliances'
      WHEN division = 'Customer Support' THEN 'Customer Support'
      WHEN division = 'Customer Service' THEN 'Customer Success'
      WHEN department = 'Data & Analytics' THEN 'Business Operations'
      ELSE NULLIF(department, '')
    END AS department,
    CASE
      WHEN department = 'Meltano' THEN 'Meltano'
      WHEN division = 'Employee' THEN NULL
      WHEN division = 'Contractor ' THEN NULL
      WHEN division = 'Alliances' THEN 'Sales'
      WHEN division = 'Customer Support' THEN 'Engineering'
      WHEN division = 'Customer Service' THEN 'Sales'
      ELSE NULLIF(division, '')
    END AS division,
    CASE
      WHEN date_actual < '2020-06-09'
        THEN FALSE
      WHEN date_actual >= '2020-06-09' AND sales_geo_differential = 'n/a - Comp Calc'
        THEN FALSE
      ELSE TRUE
    END AS exclude_from_location_factor
  FROM employee_directory_intermediate

),

final AS (

  SELECT
    {{ dbt_utils.surrogate_key(['date_actual', 'employee_id']) }} AS unique_key,
    *
  FROM cleaned

)

SELECT DISTINCT *
FROM final
