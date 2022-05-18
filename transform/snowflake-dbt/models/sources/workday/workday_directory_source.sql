WITH source AS (
  SELECT *
  FROM {{ source('workday','directory') }}
),

renamed AS (

  SELECT
    employee_id::NUMBER AS employee_id,
    work_email::VARCHAR AS work_email,
    full_name::VARCHAR AS full_name,
    job_title::VARCHAR AS job_title,
    supervisor::VARCHAR AS supervisor,
    _fivetran_synced::TIMESTAMP AS uploaded_at
  FROM source

)

SELECT *
FROM renamed