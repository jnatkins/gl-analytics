WITH crm_person AS (

    SELECT *
    FROM {{ ref('prep_crm_person') }}

), final AS (

    SELECT
      --id
      dim_crm_person_id,
      sfdc_record_id,
      bizible_person_id,
      sfdc_record_type,
      email_hash,
      email_domain,
      IFF(email_domain_type = 'Business email domain',TRUE,FALSE) AS is_valuable_signup,
      email_domain_type,
      marketo_lead_id,

      --keys
      master_record_id,
      owner_id,
      record_type_id,
      dim_crm_account_id,
      reports_to_id,
      dim_crm_user_id,
      crm_partner_id,

      --info
      person_score,
      behavior_score,
      title,
      country,
      state,
      has_opted_out_email,
      email_bounced_date,
      email_bounced_reason,
      status,
      lead_source,
      lead_source_type,
      was_converted_lead,
      source_buckets,
      employee_bucket,
      net_new_source_categories,
      bizible_touchpoint_position,
      bizible_marketing_channel_path,
      bizible_touchpoint_date,
      sequence_step_type,
      is_actively_being_sequenced,
      prospect_share_status,
      partner_prospect_status,
      partner_prospect_owner_name,
      partner_prospect_id,
      marketo_last_interesting_moment,
      marketo_last_interesting_moment_date,
      outreach_step_number,
      matched_account_owner_role,
      matched_account_account_owner_name,
      matched_account_sdr_assigned,
      matched_account_type,
      matched_account_gtm_strategy,
      is_first_order_initial_mql,
      is_first_order_mql,
      is_first_order_person,
      cognism_company_office_city,
      cognism_company_office_state,
      cognism_company_office_country,
      cognism_city,
      cognism_state,
      cognism_country,
      cognism_employee_count,
      leandata_matched_account_billing_state,
      leandata_matched_account_billing_postal_code,
      leandata_matched_account_billing_country,
      leandata_matched_account_employee_count,
      leandata_matched_account_sales_segment,
      zoominfo_contact_city,
      zoominfo_contact_state,
      zoominfo_contact_country,
      zoominfo_company_city,
      zoominfo_company_state,
      zoominfo_company_country,
      zoominfo_phone_number, 
      zoominfo_mobile_phone_number,
      zoominfo_do_not_call_direct_phone,
      zoominfo_do_not_call_mobile_phone,
      zoominfo_company_employee_count,
      account_demographics_sales_segment,
      account_demographics_sales_segment_grouped,
      account_demographics_geo,
      account_demographics_region,
      account_demographics_area,
      account_demographics_segment_region_grouped,
      account_demographics_territory,
      account_demographics_employee_count,
      account_demographics_max_family_employee,
      account_demographics_upa_country,
      account_demographics_upa_state,  
      account_demographics_upa_city,
      account_demographics_upa_street,
      account_demographics_upa_postal_code

    FROM crm_person
)

{{ dbt_audit(
    cte_ref="final",
    created_by="@jjstark",
    updated_by="@degan",
    created_date="2020-09-10",
    updated_date="2022-12-12"
) }}
