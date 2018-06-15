view: dim_opphistory {
  sql_table_name: analytics.dim_opphistory ;;

  dimension:  opportunityid{
    # hidden: yes
    type: string
    sql: ${TABLE}.opportunityid ;;
  }

  dimension: days_in_stage {
    # hidden: yes
    type: number
    sql: NULLIF(${TABLE}.days_in_stage,0) ;;
  }

  dimension: stagename {
    label: "Stage Name"
    type: string
    sql: ${TABLE}.mapped_stage ;;
  }

  measure: avg_stage_days {
    label: "Average of Days in Stage"
    type: average
    # sql: NULLIF(${days_in_stage}, 0) ;;
    sql: ${days_in_stage} ;;
    value_format: "0.#"
  }

  measure: count_of_opps {
    type: count_distinct
    sql: ${opportunityid} ;;
  }
}
