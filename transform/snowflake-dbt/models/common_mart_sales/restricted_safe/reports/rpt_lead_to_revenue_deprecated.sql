{{ simple_cte([
    ('opportunity_base','mart_crm_opportunity'),
    ('person_base','mart_crm_person'),
    ('dim_crm_person','dim_crm_person'),
    ('mart_crm_opportunity_stamped_hierarchy_hist','mart_crm_opportunity_stamped_hierarchy_hist'),
    ('rpt_sfdc_bizible_tp_opp_linear_blended','rpt_sfdc_bizible_tp_opp_linear_blended'),
    ('dim_crm_account','dim_crm_account'),
    ('map_alternative_lead_demographics','map_alternative_lead_demographics'),
    ('dim_crm_user','dim_crm_user')
]) }}

, upa_base AS ( --pulls every account and it's UPA
  
    SELECT 
      dim_parent_crm_account_id,
      dim_crm_account_id
    FROM dim_crm_account

), first_order_opps AS ( -- pulls only FO CW Opps and their UPA/Account ID

    SELECT
      dim_parent_crm_account_id,
      dim_crm_account_id,
      dim_crm_opportunity_id,
      close_date,
      is_sao,
      sales_accepted_date
    FROM opportunity_base
    WHERE is_won = true
      AND order_type = '1. New - First Order'

), accounts_with_first_order_opps AS ( -- shows only UPA/Account with a FO Available Opp on it

    SELECT
      upa_base.dim_parent_crm_account_id,
      upa_base.dim_crm_account_id,
      first_order_opps.dim_crm_opportunity_id,
      FALSE AS is_first_order_available
    FROM upa_base 
    LEFT JOIN first_order_opps
      ON upa_base.dim_crm_account_id=first_order_opps.dim_crm_account_id
    WHERE dim_crm_opportunity_id IS NOT NULL

), person_order_type_base AS (

    SELECT DISTINCT
      person_base.email_hash, 
      person_base.dim_crm_account_id,
      person_base.mql_date_lastest_pt,
      upa_base.dim_parent_crm_account_id,
      opportunity_base.dim_crm_opportunity_id,
      opportunity_base.close_date,
      opportunity_base.order_type,
      CASE 
         WHEN is_first_order_available = False AND opportunity_base.order_type = '1. New - First Order' THEN '3. Growth'
         WHEN is_first_order_available = False AND opportunity_base.order_type != '1. New - First Order' THEN opportunity_base.order_type
      ELSE '1. New - First Order'
      END AS person_order_type,
      ROW_NUMBER() OVER( PARTITION BY email_hash ORDER BY person_order_type) AS person_order_type_number
    FROM person_base
    FULL JOIN upa_base
      ON person_base.dim_crm_account_id=upa_base.dim_crm_account_id
    LEFT JOIN accounts_with_first_order_opps
      ON upa_base.dim_parent_crm_account_id = accounts_with_first_order_opps.dim_parent_crm_account_id
    FULL JOIN opportunity_base
      ON upa_base.dim_parent_crm_account_id=opportunity_base.dim_parent_crm_account_id

), person_order_type_final AS (

    SELECT DISTINCT
      person_order_type_base.email_hash,
      dim_crm_person.sfdc_record_id,
      person_order_type_base.mql_date_lastest_pt,
      person_order_type_base.dim_crm_opportunity_id,
      person_order_type_base.close_date,
      person_order_type_base.order_type,
      person_order_type_base.dim_parent_crm_account_id,
      person_order_type_base.dim_crm_account_id,
      person_order_type_base.person_order_type
    FROM person_order_type_base
    INNER JOIN dim_crm_person ON
    person_order_type_base.email_hash=dim_crm_person.email_hash
    WHERE person_order_type_number=1

), mql_order_type_base AS (

    SELECT DISTINCT
      dim_crm_person.sfdc_record_id,
      person_base.email_hash, 
      CASE 
         WHEN mql_date_lastest_pt < opportunity_base.close_date THEN opportunity_base.order_type
         WHEN mql_date_lastest_pt > opportunity_base.close_date THEN '3. Growth'
      ELSE null
      END AS mql_order_type_historical,
      ROW_NUMBER() OVER( PARTITION BY person_base.email_hash ORDER BY mql_order_type_historical) AS mql_order_type_number
    FROM person_base
    INNER JOIN dim_crm_person ON
    person_base.dim_crm_person_id=dim_crm_person.dim_crm_person_id
    FULL JOIN upa_base ON 
    person_base.dim_crm_account_id=upa_base.dim_crm_account_id
    LEFT JOIN accounts_with_first_order_opps ON
    upa_base.dim_parent_crm_account_id = accounts_with_first_order_opps.dim_parent_crm_account_id
    FULL JOIN opportunity_base ON
    upa_base.dim_parent_crm_account_id=opportunity_base.dim_parent_crm_account_id
    
), mql_order_type_final AS (
  
  SELECT *
  FROM mql_order_type_base
  WHERE mql_order_type_number=1
    
), inquiry_order_type_base AS (

    SELECT DISTINCT
      dim_crm_person.sfdc_record_id,
      person_base.email_hash, 
      CASE 
         WHEN true_inquiry_date < opportunity_base.close_date THEN opportunity_base.order_type
         WHEN true_inquiry_date > opportunity_base.close_date THEN '3. Growth'
      ELSE null
      END AS inquiry_order_type_historical,
      ROW_NUMBER() OVER( PARTITION BY person_base.email_hash ORDER BY inquiry_order_type_historical) AS inquiry_order_type_number
    FROM person_base
    INNER JOIN dim_crm_person ON
    person_base.dim_crm_person_id=dim_crm_person.dim_crm_person_id
    FULL JOIN upa_base ON 
    person_base.dim_crm_account_id=upa_base.dim_crm_account_id
    LEFT JOIN accounts_with_first_order_opps ON
    upa_base.dim_parent_crm_account_id = accounts_with_first_order_opps.dim_parent_crm_account_id
    FULL JOIN opportunity_base ON
    upa_base.dim_parent_crm_account_id=opportunity_base.dim_parent_crm_account_id

), inquiry_order_type_final AS (
  
  SELECT *
  FROM inquiry_order_type_base
  WHERE inquiry_order_type_number=1
  
), order_type_final AS (
  
  SELECT 
    person_order_type_final.sfdc_record_id,
    person_order_type_final.email_hash,
    person_order_type_final.dim_crm_account_id,
    person_order_type_final.mql_date_lastest_pt,
    person_order_type_final.close_date,
    person_order_type_final.dim_parent_crm_account_id,
    person_order_type_final.dim_crm_opportunity_id,
    person_order_type_final.order_type,
    person_order_type_final.person_order_type,
    inquiry_order_type_final.inquiry_order_type_historical,
    mql_order_type_final.mql_order_type_historical
  FROM person_order_type_final
  LEFT JOIN inquiry_order_type_final ON
  person_order_type_final.email_hash=inquiry_order_type_final.email_hash
  LEFT JOIN mql_order_type_final ON
  person_order_type_final.email_hash=mql_order_type_final.email_hash

  ), cohort_base AS (

    SELECT DISTINCT
      person_base.email_hash,
      person_base.email_domain_type,
      person_base.true_inquiry_date,
      person_base.mql_date_lastest_pt,
      person_base.status,
      person_base.lead_source,
      person_base.dim_crm_person_id,
      person_base.dim_crm_account_id,
      person_base.dim_crm_user_id,
      person_base.mql_date_first_pt,
      person_base.created_date_pt,
      person_base.created_date,
      person_base.mql_date_first,
      person_base.lead_created_date,
      person_base.lead_created_date_pt,
      person_base.contact_created_date,
      person_base.contact_created_date_pt,
      person_base.inquiry_date,
      person_base.inquiry_date_pt,
      person_base.inquiry_inferred_date,
      person_base.inquiry_inferred_date_pt,
      person_base.accepted_date,
      person_base.accepted_date_pt,
      person_base.qualifying_date,
      person_base.qualifying_date_pt,
      person_base.converted_date,
      person_base.converted_date_pt,
      person_base.worked_date,
      person_base.worked_date_pt,
      person_base.email_domain,
      person_base.is_valuable_signup,
      person_base.was_converted_lead,
      person_base.source_buckets,
      person_base.crm_partner_id,
      person_base.partner_prospect_id,
      person_base.sales_segment_name AS person_sales_segment_name,
      person_base.sales_segment_grouped AS person_sales_segment_grouped,
      person_base.person_score,
      person_base.behavior_score,
      person_base.marketo_last_interesting_moment,
      person_base.marketo_last_interesting_moment_date,
      person_base.account_demographics_segment_region_grouped,
      person_base.account_demographics_upa_country,
      person_base.account_demographics_upa_state,
      person_base.account_demographics_upa_postal_code,
      person_base.zoominfo_company_employee_count,
      person_base.is_lead_source_trial,
      person_base.is_inquiry,
      person_base.is_mql,
      dim_crm_person.sfdc_record_id,
      person_base.account_demographics_sales_segment,
      person_base.account_demographics_sales_segment_grouped,
      person_base.account_demographics_region,
      person_base.account_demographics_geo,
      person_base.account_demographics_area,
      person_base.account_demographics_territory,
      dim_crm_person.employee_bucket,
      dim_crm_person.leandata_matched_account_sales_segment,
      map_alternative_lead_demographics.employee_count_segment_custom,
	    map_alternative_lead_demographics.employee_bucket_segment_custom,
	    map_alternative_lead_demographics.geo_custom,
      is_first_order_available,
      order_type_final.person_order_type,
      order_type_final.inquiry_order_type_historical,
      order_type_final.mql_order_type_historical,
      opp.order_type AS opp_order_type,
      opp.sales_qualified_source_name,
      opp.deal_path_name,
      opp.sales_type,
      opp.dim_crm_opportunity_id,
      opp.dim_parent_crm_account_id AS opp_dim_parent_crm_account_id,
      opp.sales_accepted_date,
      opp.created_date AS opp_created_date,
      opp.close_date,
      opp.is_won,
      opp.is_sao,
      opp.new_logo_count,
      opp.net_arr,
      opp.amount,
	    opp.record_type_name,
      opp.invoice_number,
      opp.is_net_arr_closed_deal,
      opp.crm_opp_owner_sales_segment_stamped,
      opp.crm_opp_owner_region_stamped,
      opp.crm_opp_owner_area_stamped,
      opp.crm_opp_owner_geo_stamped,
      opp.parent_crm_account_demographics_upa_country,
      opp.parent_crm_account_demographics_territory,
      opp.dim_crm_user_id AS opp_dim_crm_user_id,
      opp.duplicate_opportunity_id,
      opp.merged_crm_opportunity_id,
      opp.record_type_id,
      opp.ssp_id,
      opp.dim_crm_account_id AS opp_dim_crm_account_id,
      opp.crm_account_name,
      opp.parent_crm_account_name,
      opp.opportunity_name,
      opp.stage_name,
      opp.reason_for_loss,
      opp.reason_for_loss_details,
      opp.risk_type,
      opp.risk_reasons,
      opp.downgrade_reason,
      opp.closed_buckets,
      opp.opportunity_category,
      opp.source_buckets AS opp_source_buckets,
      opp.opportunity_sales_development_representative,
      opp.opportunity_business_development_representative,
      opp.opportunity_development_representative,
      opp.sdr_or_bdr,
      opp.sdr_pipeline_contribution,
      opp.sales_path,
      opp.opportunity_deal_size,
      opp.primary_campaign_source_id AS opp_primary_campaign_source_id,
      opp.net_new_source_categories AS opp_net_new_source_categories,
      opp.deal_path_engagement,
      opp.forecast_category_name,
      opp.opportunity_owner,
      opp.churn_contraction_type,
      opp.churn_contraction_net_arr_bucket,
      opp.owner_id AS opp_owner_id,
      opp.order_type_grouped AS opp_order_type_grouped,
      opp.sales_qualified_source_grouped,
      opp.crm_account_gtm_strategy,
      opp.crm_account_focus_account,
      opp.crm_account_zi_technologies,
      opp.is_jihu_account,
      opp.fy22_new_logo_target_list,
      opp.is_closed,
      opp.is_edu_oss,
      opp.is_ps_opp,
      opp.is_win_rate_calc,
      opp.is_net_arr_pipeline_created,
      opp.is_new_logo_first_order,
      opp.is_closed_won,
      opp.is_web_portal_purchase,
      opp.is_lost,
      opp.is_open,
      opp.is_renewal,
      opp.is_duplicate,
      opp.is_refund,
      opp.is_deleted,
      opp.is_excluded_from_pipeline_created,
      opp.is_contract_reset,
      opp.is_booked_net_arr,
      opp.is_downgrade,
      opp.critical_deal_flag,
      opp.crm_user_sales_segment AS opp_crm_user_sales_segment,
      opp.crm_user_sales_segment_grouped AS opp_crm_user_sales_segment_grouped,
      opp.crm_user_geo AS opp_crm_user_geo,
      opp.crm_user_region AS opp_crm_user_region,
      opp.crm_user_area AS opp_crm_user_area,
      opp.crm_user_sales_segment_region_grouped AS opp_crm_user_sales_segment_region_grouped,
      opp.crm_account_user_sales_segment,
      opp.crm_account_user_sales_segment_grouped,
      opp.crm_account_user_geo,
      opp.crm_account_user_region,
      opp.crm_account_user_area,
      opp.crm_account_user_sales_segment_region_grouped,
      opp.sao_crm_opp_owner_sales_segment_stamped,
      opp.sao_crm_opp_owner_sales_segment_stamped_grouped,
      opp.sao_crm_opp_owner_geo_stamped,
      opp.sao_crm_opp_owner_region_stamped,
      opp.sao_crm_opp_owner_area_stamped,
      opp.sao_crm_opp_owner_segment_region_stamped_grouped,
      opp.crm_opp_owner_sales_segment_stamped_grouped,
      opp.crm_opp_owner_sales_segment_region_stamped_grouped,
      opp.opportunity_owner_user_segment,
      opp.opportunity_owner_user_geo,
      opp.opportunity_owner_user_region,
      opp.opportunity_owner_user_area,
      opp.report_opportunity_user_segment,
      opp.report_opportunity_user_geo,
      opp.report_opportunity_user_region,
      opp.report_opportunity_user_area,
      opp.report_user_segment_geo_region_area,
      opp.lead_source AS opp_lead_source,
      opp.is_public_sector_opp,
      opp.is_registration_from_portal,
      opp.stage_0_pending_acceptance_date,
      opp.stage_1_discovery_date,
      opp.stage_2_scoping_date,
      opp.stage_3_technical_evaluation_date,
      opp.stage_4_proposal_date,
      opp.stage_5_negotiating_date,
      opp.stage_6_awaiting_signature_date_date,
      opp.stage_6_closed_won_date,
      opp.stage_6_closed_lost_date,
      opp.subscription_start_date,
      opp.subscription_end_date,
      opp.pipeline_created_date,
      opp.churned_contraction_deal_count,
      opp.churned_contraction_net_arr,
      opp.calculated_deal_count,
      opp.days_in_stage,
      opp_user.user_role_name AS opp_user_role_name
    FROM person_base
    INNER JOIN dim_crm_person
      ON person_base.dim_crm_person_id=dim_crm_person.dim_crm_person_id
    LEFT JOIN upa_base
    ON person_base.dim_crm_account_id=upa_base.dim_crm_account_id
    LEFT JOIN accounts_with_first_order_opps
      ON upa_base.dim_parent_crm_account_id = accounts_with_first_order_opps.dim_parent_crm_account_id
    FULL JOIN mart_crm_opportunity_stamped_hierarchy_hist opp
      ON upa_base.dim_parent_crm_account_id=opp.dim_parent_crm_account_id
    LEFT JOIN order_type_final
      ON person_base.email_hash=order_type_final.email_hash
	LEFT JOIN map_alternative_lead_demographics
	  ON person_base.dim_crm_person_id=map_alternative_lead_demographics.dim_crm_person_id
	LEFT JOIN dim_crm_user opp_user 
		ON opp.dim_crm_user_id=opp_user.dim_crm_user_id

), fo_inquiry_with_tp AS (
  
  SELECT DISTINCT
  
    --Key IDs
    cohort_base.email_hash,
    cohort_base.dim_crm_person_id,
    cohort_base.dim_crm_opportunity_id,
    rpt_sfdc_bizible_tp_opp_linear_blended.dim_crm_touchpoint_id,
    cohort_base.sfdc_record_id,
    cohort_base.dim_crm_account_id,
    cohort_base.opp_dim_crm_account_id,
    cohort_base.opp_dim_parent_crm_account_id,
  
    --person data
    CASE 
      WHEN cohort_base.person_order_type IS null AND cohort_base.opp_order_type IS null THEN 'Missing order_type_name'
      WHEN cohort_base.person_order_type IS null THEN cohort_base.opp_order_type
      ELSE person_order_type
    END AS person_order_type,
    cohort_base.inquiry_order_type_historical,
    cohort_base.mql_order_type_historical,
    cohort_base.lead_source,    
    cohort_base.status AS crm_person_status,
    cohort_base.email_domain_type,
    cohort_base.is_valuable_signup,
    cohort_base.is_mql,
    cohort_base.account_demographics_sales_segment,
    cohort_base.account_demographics_geo,
    cohort_base.account_demographics_region,
    cohort_base.account_demographics_area,
    cohort_base.account_demographics_upa_country,
    cohort_base.account_demographics_territory,
    cohort_base.true_inquiry_date,
    cohort_base.mql_date_lastest_pt,
    cohort_base.dim_crm_user_id,
    cohort_base.mql_date_first_pt,
    cohort_base.created_date_pt,
    cohort_base.created_date,
    cohort_base.mql_date_first,
    cohort_base.lead_created_date,
    cohort_base.lead_created_date_pt,
    cohort_base.contact_created_date,
    cohort_base.contact_created_date_pt,
    cohort_base.inquiry_date,
    cohort_base.inquiry_date_pt,
    cohort_base.inquiry_inferred_date,
    cohort_base.inquiry_inferred_date_pt,
    cohort_base.accepted_date,
    cohort_base.accepted_date_pt,
    cohort_base.qualifying_date,
    cohort_base.qualifying_date_pt,
    cohort_base.converted_date,
    cohort_base.converted_date_pt,
    cohort_base.worked_date,
    cohort_base.worked_date_pt,
    cohort_base.email_domain,
    cohort_base.was_converted_lead,
    cohort_base.source_buckets,
    cohort_base.crm_partner_id,
    cohort_base.partner_prospect_id,
    cohort_base.person_sales_segment_name,
    cohort_base.person_sales_segment_grouped,
    cohort_base.person_score,
    cohort_base.behavior_score,
    cohort_base.marketo_last_interesting_moment,
    cohort_base.marketo_last_interesting_moment_date,
    cohort_base.account_demographics_segment_region_grouped,
    cohort_base.account_demographics_sales_segment_grouped,
    cohort_base.account_demographics_upa_state,
    cohort_base.account_demographics_upa_postal_code,
    cohort_base.zoominfo_company_employee_count,
    cohort_base.is_lead_source_trial,
    cohort_base.is_inquiry,
    cohort_base.employee_count_segment_custom,
    cohort_base.employee_bucket_segment_custom,
    cohort_base.geo_custom,
   
    --opportunity data
    cohort_base.opp_created_date,
    cohort_base.sales_accepted_date,
    cohort_base.close_date,
    cohort_base.is_sao,
    cohort_base.is_won,
    cohort_base.new_logo_count,
    cohort_base.net_arr,
    cohort_base.amount,
    cohort_base.invoice_number,
    cohort_base.is_net_arr_closed_deal,
    cohort_base.opp_order_type,
    cohort_base.sales_qualified_source_name,
    cohort_base.deal_path_name,
    cohort_base.sales_type,
    cohort_base.crm_opp_owner_geo_stamped,
    cohort_base.crm_opp_owner_sales_segment_stamped,
    cohort_base.crm_opp_owner_region_stamped,
    cohort_base.crm_opp_owner_area_stamped,
    cohort_base.parent_crm_account_demographics_upa_country,
    cohort_base.parent_crm_account_demographics_territory,
    cohort_base.opp_dim_crm_user_id,
    cohort_base.duplicate_opportunity_id,
    cohort_base.merged_crm_opportunity_id,
    cohort_base.record_type_id,
    cohort_base.ssp_id,
    cohort_base.opportunity_name,
    cohort_base.crm_account_name,
    cohort_base.parent_crm_account_name,
    cohort_base.stage_name,
    cohort_base.reason_for_loss,
    cohort_base.reason_for_loss_details,
    cohort_base.risk_type,
    cohort_base.risk_reasons,
    cohort_base.downgrade_reason,
    cohort_base.closed_buckets,
    cohort_base.opportunity_category,
    cohort_base.opp_source_buckets,
    cohort_base.opportunity_sales_development_representative,
    cohort_base.opportunity_business_development_representative,
    cohort_base.opportunity_development_representative,
    cohort_base.sdr_or_bdr,
    cohort_base.sdr_pipeline_contribution,
    cohort_base.sales_path,
    cohort_base.opportunity_deal_size,
    cohort_base.opp_primary_campaign_source_id,
    cohort_base.opp_net_new_source_categories,
    cohort_base.deal_path_engagement,
    cohort_base.forecast_category_name,
    cohort_base.opportunity_owner,
    cohort_base.churn_contraction_type,
    cohort_base.churn_contraction_net_arr_bucket,
    cohort_base.opp_owner_id,
    cohort_base.opp_order_type_grouped,
    cohort_base.sales_qualified_source_grouped,
    cohort_base.crm_account_gtm_strategy,
    cohort_base.crm_account_focus_account,
    cohort_base.crm_account_zi_technologies,
    cohort_base.is_jihu_account,
    cohort_base.fy22_new_logo_target_list,
    cohort_base.is_closed,
    cohort_base.is_edu_oss,
    cohort_base.is_ps_opp,
    cohort_base.is_win_rate_calc,
    cohort_base.is_net_arr_pipeline_created,
    cohort_base.is_new_logo_first_order,
    cohort_base.is_closed_won,
    cohort_base.is_web_portal_purchase,
    cohort_base.is_lost,
    cohort_base.is_open,
    cohort_base.is_renewal,
    cohort_base.is_duplicate,
    cohort_base.is_refund,
    cohort_base.is_deleted,
    cohort_base.is_excluded_from_pipeline_created,
    cohort_base.is_contract_reset,
    cohort_base.is_booked_net_arr,
    cohort_base.is_downgrade,
    cohort_base.critical_deal_flag,
    cohort_base.opp_crm_user_sales_segment,
    cohort_base.opp_crm_user_sales_segment_grouped,
    cohort_base.opp_crm_user_geo,
    cohort_base.opp_crm_user_region,
    cohort_base.opp_crm_user_area,
    cohort_base.opp_crm_user_sales_segment_region_grouped,
    cohort_base.crm_account_user_sales_segment,
    cohort_base.crm_account_user_sales_segment_grouped,
    cohort_base.crm_account_user_geo,
    cohort_base.crm_account_user_region,
    cohort_base.crm_account_user_area,
    cohort_base.crm_account_user_sales_segment_region_grouped,
    cohort_base.sao_crm_opp_owner_sales_segment_stamped,
    cohort_base.sao_crm_opp_owner_sales_segment_stamped_grouped,
    cohort_base.sao_crm_opp_owner_geo_stamped,
    cohort_base.sao_crm_opp_owner_region_stamped,
    cohort_base.sao_crm_opp_owner_area_stamped,
    cohort_base.sao_crm_opp_owner_segment_region_stamped_grouped,
    cohort_base.crm_opp_owner_sales_segment_stamped_grouped,
    cohort_base.crm_opp_owner_sales_segment_region_stamped_grouped,
    cohort_base.opportunity_owner_user_segment,
    cohort_base.opportunity_owner_user_geo,
    cohort_base.opportunity_owner_user_region,
    cohort_base.opportunity_owner_user_area,
    cohort_base.report_opportunity_user_segment,
    cohort_base.report_opportunity_user_geo,
    cohort_base.report_opportunity_user_region,
    cohort_base.report_opportunity_user_area,
    cohort_base.report_user_segment_geo_region_area,
    cohort_base.opp_lead_source,
    cohort_base.is_public_sector_opp,
    cohort_base.is_registration_from_portal,
    cohort_base.stage_0_pending_acceptance_date,
    cohort_base.stage_1_discovery_date,
    cohort_base.stage_2_scoping_date,
    cohort_base.stage_3_technical_evaluation_date,
    cohort_base.stage_4_proposal_date,
    cohort_base.stage_5_negotiating_date,
    cohort_base.stage_6_awaiting_signature_date_date,
    cohort_base.stage_6_closed_won_date,
    cohort_base.stage_6_closed_lost_date,
    cohort_base.subscription_start_date,
    cohort_base.subscription_end_date,
    cohort_base.pipeline_created_date,
    cohort_base.churned_contraction_deal_count,
    cohort_base.churned_contraction_net_arr,
    cohort_base.calculated_deal_count,
    cohort_base.days_in_stage,
    cohort_base.opp_user_role_name,
	cohort_base.record_type_name,
    CASE
      WHEN rpt_sfdc_bizible_tp_opp_linear_blended.dim_crm_touchpoint_id IS NOT null THEN cohort_base.dim_crm_opportunity_id
      ELSE null
    END AS influenced_opportunity_id,
  
    --touchpoint data
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_touchpoint_date_normalized,
    rpt_sfdc_bizible_tp_opp_linear_blended.gtm_motion,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_integrated_campaign_grouping,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_marketing_channel_path,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_marketing_channel,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_ad_campaign_name,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_form_url,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_landing_page,
    rpt_sfdc_bizible_tp_opp_linear_blended.is_dg_influenced,
    rpt_sfdc_bizible_tp_opp_linear_blended.is_fmm_influenced,
    rpt_sfdc_bizible_tp_opp_linear_blended.mql_sum,
    rpt_sfdc_bizible_tp_opp_linear_blended.inquiry_sum,
    rpt_sfdc_bizible_tp_opp_linear_blended.accepted_sum,
    rpt_sfdc_bizible_tp_opp_linear_blended.linear_opp_created,
    rpt_sfdc_bizible_tp_opp_linear_blended.linear_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.linear_sao,
    rpt_sfdc_bizible_tp_opp_linear_blended.pipeline_linear_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.won_linear,
    rpt_sfdc_bizible_tp_opp_linear_blended.won_linear_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.w_shaped_sao,
    rpt_sfdc_bizible_tp_opp_linear_blended.pipeline_w_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.won_w,
    rpt_sfdc_bizible_tp_opp_linear_blended.won_w_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.u_shaped_sao,
    rpt_sfdc_bizible_tp_opp_linear_blended.pipeline_u_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.won_u,
    rpt_sfdc_bizible_tp_opp_linear_blended.won_u_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.first_sao,
    rpt_sfdc_bizible_tp_opp_linear_blended.pipeline_first_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.won_first,
    rpt_sfdc_bizible_tp_opp_linear_blended.won_first_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.custom_sao,
    rpt_sfdc_bizible_tp_opp_linear_blended.pipeline_custom_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.won_custom,
    rpt_sfdc_bizible_tp_opp_linear_blended.won_custom_net_arr,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_touchpoint_position,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_touchpoint_source,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_touchpoint_type,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_ad_content,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_ad_group_name,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_form_url_raw,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_landing_page_raw,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_medium,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_referrer_page,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_referrer_page_raw,
    rpt_sfdc_bizible_tp_opp_linear_blended.bizible_salesforce_campaign,
	rpt_sfdc_bizible_tp_opp_linear_blended.dim_campaign_id,
	rpt_sfdc_bizible_tp_opp_linear_blended.campaign_rep_role_name,
    rpt_sfdc_bizible_tp_opp_linear_blended.touchpoint_segment,
    rpt_sfdc_bizible_tp_opp_linear_blended.pipe_name
  FROM cohort_base
  LEFT JOIN rpt_sfdc_bizible_tp_opp_linear_blended
    ON rpt_sfdc_bizible_tp_opp_linear_blended.email_hash=cohort_base.email_hash

), final_prep AS (

    SELECT 
	fo_inquiry_with_tp.*,
    COALESCE(employee_count_segment_custom,employee_bucket_segment_custom) AS inferred_employee_segment,
    UPPER(geo_custom) AS inferred_geo
    FROM fo_inquiry_with_tp

), final AS (

  SELECT *
  FROM final_prep

)


{{ dbt_audit(
    cte_ref="final",
    created_by="@rkohnke",
    updated_by="@rkohnke",
    created_date="2022-07-20",
    updated_date="2022-12-06",
  ) }}
