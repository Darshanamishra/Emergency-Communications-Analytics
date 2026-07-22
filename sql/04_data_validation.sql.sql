USE ROLE ACCOUNTADMIN;
USE WAREHOUSE EMERGENCY_ANALYTICS_WH;
USE DATABASE EMERGENCY_ANALYTICS;
USE SCHEMA RAW;

--Check a sample of the data
SELECT * FROM raw_calls
LIMIT 10;


SELECT COUNT(*) AS total_rows
FROM raw_calls;

--Check the load history
SELECT
    file_name,
    status,
    row_count,
    row_parsed,
    first_error_message,
    last_load_time
FROM information_schema.load_history
WHERE table_name = 'RAW_CALLS'
ORDER BY last_load_time DESC;


--Check for duplicate call IDs
SELECT
    call_id,
    COUNT(*) AS record_count
FROM raw_calls
GROUP BY call_id
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

--Check for missing required values
SELECT
    COUNT_IF(call_id IS NULL OR TRIM(call_id) = '') AS missing_call_id,
    COUNT_IF(received_timestamp IS NULL OR TRIM(received_timestamp) = '') 
        AS missing_received_timestamp,
    COUNT_IF(call_type IS NULL OR TRIM(call_type) = '') AS missing_call_type,
    COUNT_IF(priority_level IS NULL OR TRIM(priority_level) = '') 
        AS missing_priority_level,
    COUNT_IF(region IS NULL OR TRIM(region) = '') AS missing_region
FROM raw_calls;


--Check whether timestamps can be converted
SELECT
    COUNT_IF(
        received_timestamp IS NOT NULL
        AND TRY_TO_TIMESTAMP_NTZ(received_timestamp) IS NULL
    ) AS invalid_received_timestamp,

    COUNT_IF(
        answered_timestamp IS NOT NULL
        AND TRY_TO_TIMESTAMP_NTZ(answered_timestamp) IS NULL
    ) AS invalid_answered_timestamp,

    COUNT_IF(
        completed_timestamp IS NOT NULL
        AND TRY_TO_TIMESTAMP_NTZ(completed_timestamp) IS NULL
    ) AS invalid_completed_timestamp
FROM raw_calls;

--Check numeric conversion
SELECT
    COUNT_IF(
        service_target_seconds IS NOT NULL
        AND TRY_TO_NUMBER(service_target_seconds) IS NULL
    ) AS invalid_service_target_seconds
FROM raw_calls;

--Review category values
SELECT call_type, COUNT(*) AS total_calls
FROM raw_calls
GROUP BY call_type
ORDER BY total_calls DESC;

SELECT priority_level, COUNT(*) AS total_calls
FROM raw_calls
GROUP BY priority_level
ORDER BY priority_level;

SELECT region, COUNT(*) AS total_calls
FROM raw_calls
GROUP BY region
ORDER BY region;

SELECT abandoned_flag, COUNT(*) AS total_calls
FROM raw_calls
GROUP BY abandoned_flag;

SELECT transferred_flag, COUNT(*) AS total_calls
FROM raw_calls
GROUP BY transferred_flag;

--Check time sequence problems
SELECT
    COUNT_IF(
        TRY_TO_TIMESTAMP_NTZ(answered_timestamp)
        < TRY_TO_TIMESTAMP_NTZ(received_timestamp)
    ) AS answered_before_received,

    COUNT_IF(
        TRY_TO_TIMESTAMP_NTZ(completed_timestamp)
        < TRY_TO_TIMESTAMP_NTZ(received_timestamp)
    ) AS completed_before_received,

    COUNT_IF(
        TRY_TO_TIMESTAMP_NTZ(completed_timestamp)
        < TRY_TO_TIMESTAMP_NTZ(answered_timestamp)
    ) AS completed_before_answered
FROM raw_calls;