{% snapshot zuora_revenue_revenue_contract_schedule_snapshots %}

    {{
        config(
          strategy='timestamp',
          unique_key='rc_id',
          updated_at='incr_updt_dt',
        )
    }}
    
    SELECT * 
    FROM {{ source('zuora_revenue','zuora_revenue_revenue_contract_schedule') }}
    QUALIFY RANK() OVER (PARTITION BY rc_id ORDER BY incr_updt_dt DESC) = 1

{% endsnapshot %}
