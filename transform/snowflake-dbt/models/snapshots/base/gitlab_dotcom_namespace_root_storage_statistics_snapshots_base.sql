{{ config({
    "schema": "staging",
    "alias": "gitlab_dotcom_namespace_root_storage_statistics_snapshots"
    })
}}

WITH source AS (

    SELECT *
    FROM {{ source('snapshots', 'gitlab_dotcom_namespace_root_storage_statistics_snapshots') }}
    
), renamed as (

    SELECT
        dbt_scd_id::VARCHAR                                           AS namespace_storage_statistics_snapshot_id,
        namespace_id::INTEGER                                         AS namespace_id,
        repository_size::INTEGER                                      AS repository_size,
        lfs_objects_size::INTEGER                                     AS lfs_objects_size,
        wiki_size::INTEGER                                            AS wiki_size,
        build_artifacts_size::INTEGER                                 AS build_artifacts_size,
        storage_size::INTEGER                                         AS storage_size,
        packages_size::INTEGER                                        AS packages_size,
        dbt_valid_from::TIMESTAMP                                     AS valid_from,
        dbt_valid_to::TIMESTAMP                                       AS valid_to

    FROM source
    
)

SELECT *
FROM renamed
