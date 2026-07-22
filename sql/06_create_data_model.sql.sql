USE ROLE ACCOUNTADMIN;
USE WAREHOUSE EMERGENCY_ANALYTICS_WH;
USE DATABASE EMERGENCY_ANALYTICS;
USE SCHEMA ANALYTICS;

-- Create date dimension
CREATE OR REPLACE TABLE dim_date AS
SELECT
    ROW_NUMBER() OVER (ORDER BY call_date) AS date_key,
    call_date,
    YEAR(call_date) AS year,
    QUARTER(call_date) AS quarter_number,
    MONTH(call_date) AS month_number,
    MONTHNAME(call_date) AS month_name,
    WEEKOFYEAR(call_date) AS week_number,
    DAYOFMONTH(call_date) AS day_of_month,
    DAYOFWEEKISO(call_date) AS day_of_week_number,
    DAYNAME(call_date) AS day_name,
    CASE
        WHEN DAYOFWEEKISO(call_date) IN (6, 7) THEN TRUE
        ELSE FALSE
    END AS is_weekend
FROM (
    SELECT DISTINCT call_date
    FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean
    WHERE call_date IS NOT NULL
);

-- Create call type dimension
CREATE OR REPLACE TABLE dim_call_type AS
SELECT
    ROW_NUMBER() OVER (ORDER BY call_type) AS call_type_key,
    call_type
FROM (
    SELECT DISTINCT call_type
    FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean
    WHERE call_type IS NOT NULL
);

-- Create priority dimension
CREATE OR REPLACE TABLE dim_priority AS
SELECT
    ROW_NUMBER() OVER (ORDER BY priority_level) AS priority_key,
    priority_level
FROM (
    SELECT DISTINCT priority_level
    FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean
    WHERE priority_level IS NOT NULL
);

-- Create region dimension
CREATE OR REPLACE TABLE dim_region AS
SELECT
    ROW_NUMBER() OVER (ORDER BY region) AS region_key,
    region
FROM (
    SELECT DISTINCT region
    FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean
    WHERE region IS NOT NULL
);

-- Create channel dimension
CREATE OR REPLACE TABLE dim_channel AS
SELECT
    ROW_NUMBER() OVER (ORDER BY channel) AS channel_key,
    channel
FROM (
    SELECT DISTINCT channel
    FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean
    WHERE channel IS NOT NULL
);

-- Create caller language dimension
CREATE OR REPLACE TABLE dim_language AS
SELECT
    ROW_NUMBER() OVER (ORDER BY caller_language) AS language_key,
    caller_language
FROM (
    SELECT DISTINCT caller_language
    FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean
    WHERE caller_language IS NOT NULL
);

-- Create disposition dimension
CREATE OR REPLACE TABLE dim_disposition AS
SELECT
    ROW_NUMBER() OVER (ORDER BY disposition) AS disposition_key,
    disposition
FROM (
    SELECT DISTINCT disposition
    FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean
    WHERE disposition IS NOT NULL
);

-- Create operator dimension
CREATE OR REPLACE TABLE dim_operator AS
SELECT
    ROW_NUMBER() OVER (ORDER BY operator_id) AS operator_key,
    operator_id
FROM (
    SELECT DISTINCT operator_id
    FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean
    WHERE operator_id IS NOT NULL
);

-- Create fact table
CREATE OR REPLACE TABLE fact_calls AS
SELECT
    c.call_id,

    d.date_key,
    ct.call_type_key,
    p.priority_key,
    r.region_key,
    ch.channel_key,
    l.language_key,
    ds.disposition_key,
    o.operator_key,

    c.received_timestamp,
    c.answered_timestamp,
    c.completed_timestamp,

    c.call_hour,
    c.call_hour_number,

    c.abandoned_flag,
    c.transferred_flag,
    c.service_target_met,

    c.service_target_seconds,
    c.answer_wait_seconds,
    c.handling_seconds,
    c.total_call_seconds,

    1 AS call_count

FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean c

LEFT JOIN dim_date d
    ON c.call_date = d.call_date

LEFT JOIN dim_call_type ct
    ON c.call_type = ct.call_type

LEFT JOIN dim_priority p
    ON c.priority_level = p.priority_level

LEFT JOIN dim_region r
    ON c.region = r.region

LEFT JOIN dim_channel ch
    ON c.channel = ch.channel

LEFT JOIN dim_language l
    ON c.caller_language = l.caller_language

LEFT JOIN dim_disposition ds
    ON c.disposition = ds.disposition

LEFT JOIN dim_operator o
    ON c.operator_id = o.operator_id;

-- Compare transformed and fact table row counts
SELECT
    (SELECT COUNT(*)
     FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean) AS clean_rows,

    (SELECT COUNT(*)
     FROM EMERGENCY_ANALYTICS.ANALYTICS.fact_calls) AS fact_rows;

-- Check for duplicate call IDs
SELECT
    call_id,
    COUNT(*) AS record_count
FROM fact_calls
GROUP BY call_id
HAVING COUNT(*) > 1;

-- Check for missing dimension keys
SELECT
    COUNT_IF(date_key IS NULL) AS missing_date_key,
    COUNT_IF(call_type_key IS NULL) AS missing_call_type_key,
    COUNT_IF(priority_key IS NULL) AS missing_priority_key,
    COUNT_IF(region_key IS NULL) AS missing_region_key,
    COUNT_IF(channel_key IS NULL) AS missing_channel_key,
    COUNT_IF(language_key IS NULL) AS missing_language_key,
    COUNT_IF(disposition_key IS NULL) AS missing_disposition_key,
    COUNT_IF(operator_key IS NULL) AS missing_operator_key
FROM fact_calls;

-- Show all tables created in the analytics schema
SHOW TABLES IN SCHEMA EMERGENCY_ANALYTICS.ANALYTICS;