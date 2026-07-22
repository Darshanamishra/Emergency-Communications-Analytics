USE ROLE ACCOUNTADMIN;
USE WAREHOUSE EMERGENCY_ANALYTICS_WH;
USE DATABASE EMERGENCY_ANALYTICS;
USE SCHEMA TRANSFORMED;

CREATE OR REPLACE TABLE calls_clean AS
SELECT
    call_id,

    TRY_TO_TIMESTAMP_NTZ(received_timestamp) AS received_timestamp,
    TRY_TO_TIMESTAMP_NTZ(answered_timestamp) AS answered_timestamp,
    TRY_TO_TIMESTAMP_NTZ(completed_timestamp) AS completed_timestamp,

    TRIM(call_type) AS call_type,
    TRIM(priority_level) AS priority_level,
    TRIM(region) AS region,
    TRIM(channel) AS channel,
    TRIM(caller_language) AS caller_language,
    TRIM(disposition) AS disposition,

    TRY_TO_BOOLEAN(abandoned_flag) AS abandoned_flag,
    TRY_TO_BOOLEAN(transferred_flag) AS transferred_flag,

    TRIM(operator_id) AS operator_id,
    TRY_TO_NUMBER(service_target_seconds) AS service_target_seconds,

    DATEDIFF(
        SECOND,
        TRY_TO_TIMESTAMP_NTZ(received_timestamp),
        TRY_TO_TIMESTAMP_NTZ(answered_timestamp)
    ) AS answer_wait_seconds,

    DATEDIFF(
        SECOND,
        TRY_TO_TIMESTAMP_NTZ(answered_timestamp),
        TRY_TO_TIMESTAMP_NTZ(completed_timestamp)
    ) AS handling_seconds,

    DATEDIFF(
        SECOND,
        TRY_TO_TIMESTAMP_NTZ(received_timestamp),
        TRY_TO_TIMESTAMP_NTZ(completed_timestamp)
    ) AS total_call_seconds,

    CASE
        WHEN TRY_TO_TIMESTAMP_NTZ(answered_timestamp) IS NULL THEN FALSE
        WHEN DATEDIFF(
            SECOND,
            TRY_TO_TIMESTAMP_NTZ(received_timestamp),
            TRY_TO_TIMESTAMP_NTZ(answered_timestamp)
        ) <= TRY_TO_NUMBER(service_target_seconds)
        THEN TRUE
        ELSE FALSE
    END AS service_target_met,

    TO_DATE(TRY_TO_TIMESTAMP_NTZ(received_timestamp)) AS call_date,

    DATE_TRUNC(
        HOUR,
        TRY_TO_TIMESTAMP_NTZ(received_timestamp)
    ) AS call_hour,

    DAYNAME(
        TRY_TO_TIMESTAMP_NTZ(received_timestamp)
    ) AS call_day_name,

    DATE_PART(
        HOUR,
        TRY_TO_TIMESTAMP_NTZ(received_timestamp)
    ) AS call_hour_number,

    loaded_at,
    CURRENT_TIMESTAMP() AS transformed_at

FROM EMERGENCY_ANALYTICS.RAW.raw_calls;

---                  Validate the transformed table           ----

-- Compare row counts
SELECT
    (SELECT COUNT(*)
     FROM EMERGENCY_ANALYTICS.RAW.raw_calls) AS raw_rows,

    (SELECT COUNT(*)
     FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean) AS transformed_rows;

--Review the data types
DESCRIBE TABLE EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean;

--Review sample records
SELECT
    call_id,
    received_timestamp,
    answered_timestamp,
    call_type,
    abandoned_flag,
    answer_wait_seconds,
    service_target_seconds,
    service_target_met,
    call_date,
    call_hour
FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean
LIMIT 20;

--Check for failed conversions
SELECT
    COUNT_IF(received_timestamp IS NULL) AS missing_received_timestamp,
    COUNT_IF(service_target_seconds IS NULL) AS missing_service_target,
    COUNT_IF(abandoned_flag IS NULL) AS invalid_abandoned_flag,
    COUNT_IF(transferred_flag IS NULL) AS invalid_transferred_flag
FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean;


--Check calculated durations
SELECT
    MIN(answer_wait_seconds) AS minimum_wait_seconds,
    MAX(answer_wait_seconds) AS maximum_wait_seconds,
    AVG(answer_wait_seconds) AS average_wait_seconds,

    MIN(handling_seconds) AS minimum_handling_seconds,
    MAX(handling_seconds) AS maximum_handling_seconds,
    AVG(handling_seconds) AS average_handling_seconds
FROM EMERGENCY_ANALYTICS.TRANSFORMED.calls_clean;
