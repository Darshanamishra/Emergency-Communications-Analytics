USE ROLE ACCOUNTADMIN;
USE WAREHOUSE EMERGENCY_ANALYTICS_WH;
USE DATABASE EMERGENCY_ANALYTICS;
USE SCHEMA ANALYTICS;


-- Detailed reporting view
CREATE OR REPLACE VIEW vw_calls_detail AS
SELECT
    f.call_id,

    d.call_date,
    d.year,
    d.quarter_number,
    d.month_number,
    d.month_name,
    d.week_number,
    d.day_of_month,
    d.day_of_week_number,
    d.day_name,
    d.is_weekend,

    ct.call_type,
    p.priority_level,
    r.region,
    ch.channel,
    l.caller_language,
    ds.disposition,
    o.operator_id,

    f.received_timestamp,
    f.answered_timestamp,
    f.completed_timestamp,
    f.call_hour,
    f.call_hour_number,

    f.abandoned_flag,
    f.transferred_flag,
    f.service_target_met,

    f.service_target_seconds,
    f.answer_wait_seconds,
    f.handling_seconds,
    f.total_call_seconds,
    f.call_count

FROM fact_calls f

LEFT JOIN dim_date d
    ON f.date_key = d.date_key

LEFT JOIN dim_call_type ct
    ON f.call_type_key = ct.call_type_key

LEFT JOIN dim_priority p
    ON f.priority_key = p.priority_key

LEFT JOIN dim_region r
    ON f.region_key = r.region_key

LEFT JOIN dim_channel ch
    ON f.channel_key = ch.channel_key

LEFT JOIN dim_language l
    ON f.language_key = l.language_key

LEFT JOIN dim_disposition ds
    ON f.disposition_key = ds.disposition_key

LEFT JOIN dim_operator o
    ON f.operator_key = o.operator_key;


-- Daily KPI view
CREATE OR REPLACE VIEW vw_daily_kpis AS
SELECT
    d.call_date,
    d.year,
    d.month_number,
    d.month_name,
    d.day_name,

    COUNT(*) AS total_calls,

    COUNT_IF(f.abandoned_flag = TRUE) AS abandoned_calls,

    COUNT_IF(f.transferred_flag = TRUE) AS transferred_calls,

    COUNT_IF(f.service_target_met = TRUE) AS calls_meeting_target,

    ROUND(
        DIV0NULL(
            COUNT_IF(f.abandoned_flag = TRUE) * 100.0,
            COUNT(*)
        ),
        2
    ) AS abandonment_rate_pct,

    ROUND(
        DIV0NULL(
            COUNT_IF(f.transferred_flag = TRUE) * 100.0,
            COUNT(*)
        ),
        2
    ) AS transfer_rate_pct,

    ROUND(
        DIV0NULL(
            COUNT_IF(f.service_target_met = TRUE) * 100.0,
            COUNT(*)
        ),
        2
    ) AS service_level_pct,

    ROUND(AVG(f.answer_wait_seconds), 2)
        AS average_answer_wait_seconds,

    ROUND(AVG(f.handling_seconds), 2)
        AS average_handling_seconds,

    ROUND(AVG(f.total_call_seconds), 2)
        AS average_total_call_seconds

FROM fact_calls f

LEFT JOIN dim_date d
    ON f.date_key = d.date_key

GROUP BY
    d.call_date,
    d.year,
    d.month_number,
    d.month_name,
    d.day_name;


-- Hourly performance view
CREATE OR REPLACE VIEW vw_hourly_performance AS
SELECT
    f.call_hour_number,

    COUNT(*) AS total_calls,

    COUNT_IF(f.abandoned_flag = TRUE) AS abandoned_calls,

    COUNT_IF(f.service_target_met = TRUE) AS calls_meeting_target,

    ROUND(
        DIV0NULL(
            COUNT_IF(f.abandoned_flag = TRUE) * 100.0,
            COUNT(*)
        ),
        2
    ) AS abandonment_rate_pct,

    ROUND(
        DIV0NULL(
            COUNT_IF(f.service_target_met = TRUE) * 100.0,
            COUNT(*)
        ),
        2
    ) AS service_level_pct,

    ROUND(AVG(f.answer_wait_seconds), 2)
        AS average_answer_wait_seconds,

    ROUND(AVG(f.handling_seconds), 2)
        AS average_handling_seconds

FROM fact_calls f

GROUP BY f.call_hour_number;


-- Region performance view
CREATE OR REPLACE VIEW vw_region_performance AS
SELECT
    r.region,

    COUNT(*) AS total_calls,

    COUNT_IF(f.abandoned_flag = TRUE) AS abandoned_calls,

    COUNT_IF(f.transferred_flag = TRUE) AS transferred_calls,

    COUNT_IF(f.service_target_met = TRUE) AS calls_meeting_target,

    ROUND(
        DIV0NULL(
            COUNT_IF(f.abandoned_flag = TRUE) * 100.0,
            COUNT(*)
        ),
        2
    ) AS abandonment_rate_pct,

    ROUND(
        DIV0NULL(
            COUNT_IF(f.service_target_met = TRUE) * 100.0,
            COUNT(*)
        ),
        2
    ) AS service_level_pct,

    ROUND(AVG(f.answer_wait_seconds), 2)
        AS average_answer_wait_seconds,

    ROUND(AVG(f.handling_seconds), 2)
        AS average_handling_seconds

FROM fact_calls f

LEFT JOIN dim_region r
    ON f.region_key = r.region_key

GROUP BY r.region;


-- Priority performance view
CREATE OR REPLACE VIEW vw_priority_performance AS
SELECT
    p.priority_level,

    COUNT(*) AS total_calls,

    COUNT_IF(f.abandoned_flag = TRUE) AS abandoned_calls,

    COUNT_IF(f.service_target_met = TRUE) AS calls_meeting_target,

    ROUND(
        DIV0NULL(
            COUNT_IF(f.abandoned_flag = TRUE) * 100.0,
            COUNT(*)
        ),
        2
    ) AS abandonment_rate_pct,

    ROUND(
        DIV0NULL(
            COUNT_IF(f.service_target_met = TRUE) * 100.0,
            COUNT(*)
        ),
        2
    ) AS service_level_pct,

    ROUND(AVG(f.answer_wait_seconds), 2)
        AS average_answer_wait_seconds,

    ROUND(AVG(f.handling_seconds), 2)
        AS average_handling_seconds

FROM fact_calls f

LEFT JOIN dim_priority p
    ON f.priority_key = p.priority_key

GROUP BY p.priority_level;


-- Confirm all views were created
SHOW VIEWS IN SCHEMA EMERGENCY_ANALYTICS.ANALYTICS;

------       Validate the views      ------

SELECT COUNT(*) AS detail_rows
FROM vw_calls_detail;

SELECT *
FROM vw_daily_kpis
ORDER BY call_date
LIMIT 10;

SELECT *
FROM vw_hourly_performance
ORDER BY call_hour_number;

SELECT *
FROM vw_region_performance
ORDER BY total_calls DESC;

SELECT *
FROM vw_priority_performance
ORDER BY priority_level;
