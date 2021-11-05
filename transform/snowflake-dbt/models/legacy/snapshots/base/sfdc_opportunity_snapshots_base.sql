{{ config(
    tags=["mnpi","mnpi_exception"]
) }}

-- PENDING SCHEMA MIGRATION

{{ config({
    "alias": "sfdc_opportunity_snapshots",
    })
}}

{{ create_snapshot_base(
    source=source('snapshots', 'sfdc_opportunity_snapshots'),
    primary_key='id',
    date_start='2019-10-01',
    date_part='day',
    snapshot_id_name='opportunity_snapshot_id' 
    )
}}

SELECT *
FROM final
