USE ROLE ACCOUNTADMIN;
USE WAREHOUSE EMERGENCY_ANALYTICS_WH;
USE DATABASE EMERGENCY_ANALYTICS;
USE SCHEMA RAW;

CREATE OR REPLACE FILE FORMAT emergency_csv_format
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    EMPTY_FIELD_AS_NULL = TRUE;

CREATE OR REPLACE STAGE emergency_raw_stage
    FILE_FORMAT = emergency_csv_format;


COPY INTO raw_calls (
    call_id,
    received_timestamp,
    answered_timestamp,
    completed_timestamp,
    call_type,
    priority_level,
    region,
    channel,
    caller_language,
    disposition,
    abandoned_flag,
    transferred_flag,
    operator_id,
    service_target_seconds
)
FROM (
    SELECT
        $1,
        $2,
        $3,
        $4,
        $5,
        $6,
        $7,
        $8,
        $9,
        $10,
        $11,
        $12,
        $13,
        $14
    FROM @emergency_raw_stage/raw
)
FILE_FORMAT = (
    FORMAT_NAME = emergency_csv_format
)
ON_ERROR = 'ABORT_STATEMENT';



