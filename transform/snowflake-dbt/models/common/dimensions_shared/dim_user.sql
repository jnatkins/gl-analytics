WITH prep_user AS (

    SELECT 
      --surrogate_key
      dim_user_sk,
      
      --natural_key
      user_id,
      
      --legacy natural_key to be deprecated during change management plan
      dim_user_id,
      
      --Other attributes
      remember_created_at,
      sign_in_count,
      current_sign_in_at,
      last_sign_in_at,
      created_at,
      updated_at,
      is_admin,
      is_blocked_user,
      notification_email_domain,
      notification_email_domain_classification,
      email_domain,
      email_domain_classification,
      IFF(email_domain_classification IS NULL,TRUE,FALSE) AS is_valuable_signup,
      public_email_domain,
      public_email_domain_classification,
      commit_email_domain,
      commit_email_domain_classification,
      identity_provider,
      role,
      last_activity_date,              
      last_sign_in_date,               
      setup_for_company,               
      jobs_to_be_done,
      for_business_use,                 
      employee_count,
      country,
      state
 
    FROM {{ ref('prep_user') }}
    
    UNION ALL
    
    SELECT
      --surrogate_key
      {{ dbt_utils.surrogate_key(['-1']) }}                  AS dim_user_sk,
      
      --natural_key
      -1 AS user_id,
      
      --legacy natural_key to be deprecated during change management plan
      -1 AS dim_user_id,
      
      --Other attributes
      '9999-12-31 00:00:00.000 +0000' AS remember_created_at,
      -1 AS sign_in_count,
      '9999-12-31 00:00:00.000 +0000' AS current_sign_in_at,
      '9999-12-31 00:00:00.000 +0000' AS last_sign_in_at,
      '9999-12-31 00:00:00.000 +0000' AS created_at,
      '9999-12-31 00:00:00.000 +0000' AS updated_at,
      0 AS is_admin,
      0 AS is_blocked_user,
      'Missing notification_email_domain' AS notification_email_domain,
      'Missing notification_email_domain_classification' AS notification_email_domain_classification,
      'Missing email_domain' AS email_domain,
      'Missing email_domain_classification' AS email_domain_classification,
      FALSE AS is_valuable_signup,
      'Missing public_email_domain' AS public_email_domain,
      'Missing public_email_domain_classification' AS public_email_domain_classification,
      'Missing commit_email_domain' AS commit_email_domain,
      'Missing commit_email_domain_classification' AS commit_email_domain_classification,
      'Missing identity_provider' AS identity_provider,
      'Missing role' AS role,
      'Missing last_activity_date' AS last_activity_date,              
      'Missing last_sign_in_date' AS last_sign_in_date,
      'Missing setup_for_company' AS setup_for_company,               
      'Missing jobs_to_be_done' AS jobs_to_be_done,
      'Missing for_business_use' AS for_business_use,                 
      'Missing employee_count' AS employee_count,
      'Missing country' AS country,
      'Missing state' AS state
)

{{ dbt_audit(
    cte_ref="prep_user",
    created_by="@mpeychet_",
    updated_by="@tpoole",
    created_date="2021-06-28",
    updated_date="2022-08-31"
) }}
