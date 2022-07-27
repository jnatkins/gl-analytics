WITH source AS (

    SELECT *
    FROM {{ source('monte_carlo_prod_insights', 'key_assets') }}

), renamed AS (

    SELECT
     *
    FROM source

)

SELECT *
FROM renamed