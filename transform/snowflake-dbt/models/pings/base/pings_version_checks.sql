with source AS (

  SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated_at DESC) as rank_in_key
  FROM {{ source('pings_tap_postgres', 'version_checks') }}

), renamed AS (

  SELECT  id,
          host_id,

          created_at,
          updated_at,

          gitlab_version,
          referer_url,
          request_data
  FROM source
  WHERE rank_in_key = 1
)

SELECT * 
FROM renamed
