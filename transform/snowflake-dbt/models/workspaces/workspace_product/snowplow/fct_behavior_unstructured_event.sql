{{ config(
    
        materialized = "incremental",
        unique_key = "fct_behavior_unstructured_sk",
        full_refresh = only_force_full_refresh(),
        on_schema_change = 'sync_all_columns',
        cluster_by = ['behavior_at::DATE']

) }}

{{ simple_cte([
    ('events', 'prep_snowplow_unnested_events_all'),
    ])
}}

, unstruct_event AS (

    SELECT
      event_id,
      behavior_at,
      event,
      dim_behavior_event_sk,
      platform,
      gsc_pseudonymized_user_id,
      clean_url_path,
      page_url_host,
      app_id,
      session_id,
      link_click_target_url,
      submit_form_id,
      change_form_id,
      change_form_type,
      change_form_element_id,
      focus_form_element_id,
      focus_form_node_name,
      dim_behavior_browser_sk,
      dim_behavior_operating_system_sk,
      dim_behavior_website_page_sk,
      dim_behavior_referrer_page_sk,
      environment
    FROM events
    WHERE event = 'unstruct'

    {% if is_incremental() %}

      AND behavior_at > (SELECT MAX({{ var('incremental_backfill_date', 'behavior_at') }}) FROM {{ this }})
      AND behavior_at <= (SELECT DATEADD(month, 1,  MAX({{ var('incremental_backfill_date', 'behavior_at') }}) )  FROM {{ this }})

    {% endif %}

), unstruct_event_with_dims AS (

    SELECT

      -- Primary Key
      {{ dbt_utils.surrogate_key(['event_id','behavior_at']) }} AS fct_behavior_unstructured_sk,

      -- Natural Key
      unstruct_event.app_id,
      unstruct_event.event_id,
      unstruct_event.session_id,

      -- Surrogate Keys
      unstruct_event.dim_behavior_event_sk,
      unstruct_event.dim_behavior_website_page_sk,
      unstruct_event.dim_behavior_referrer_page_sk,
      unstruct_event.dim_behavior_browser_sk,
      unstruct_event.dim_behavior_operating_system_sk,

      --Time Attributes
      behavior_at,

      -- Google Key
      gsc_pseudonymized_user_id,

      -- Attributes
      link_click_target_url,
      submit_form_id,
      change_form_id,
      change_form_type,
      change_form_element_id,
      focus_form_element_id,
      focus_form_node_name
    FROM unstruct_event
      
)

{{ dbt_audit(
    cte_ref="unstruct_event_with_dims",
    created_by="@chrissharp",
    updated_by="@chrissharp",
    created_date="2022-09-27",
    updated_date="2022-12-01"
) }}