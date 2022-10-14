{{ config({
    "materialized": "incremental",
    "unique_key": "id",
    tags=["mnpi_exception"]
    })
}}

SELECT *
FROM {{ source('gitlab_dotcom', 'protected_branch_merge_access_levels') }}
{% if is_incremental() %}

WHERE _uploaded_at >= (SELECT MAX(_uploaded_at) FROM {{this}})

{% endif %}
QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY _uploaded_at DESC) = 1
