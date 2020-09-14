{% macro source_new_rows_per_day(schema, table, created_column, min_value, max_value=None, where_clause=None) %}

WITH dates as (

    SELECT *
    FROM {{ ref('date_details' )}}
    WHERE is_holiday = FALSE
    AND day_of_week IN (2,3,4,5,6)

), source as (

    SELECT *
    FROM {{ source(schema, table) }}

), counts AS (

    SELECT 
      COUNT(*)                                          AS row_count,
      DATEADD('day', -1, DATE_TRUNC('day',createddate)) AS the_day
    FROM source
    WHERE the_day IN (SELECT DATE_ACTUAL FROM dates)
    {% if where_clause != None %}
      AND {{ where_clause }}
    {% endif %}
    GROUP BY 2
    ORDER BY 2 DESC
    LIMIT 1

)

SELECT row_count
FROM counts
WHERE row_count < {{ min_value }} 
    {% if max_value != None %}
      OR row_count > {{ max_value }}
    {% endif %}

{% endmacro %}
