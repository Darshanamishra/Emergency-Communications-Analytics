USE ROLE ACCOUNTADMIN;
USE WAREHOUSE EMERGENCY_ANALYTICS_WH;
USE DATABASE EMERGENCY_ANALYTICS;
USE SCHEMA RAW;

CREATE OR REPLACE TABLE raw_calls (
    call_id VARCHAR,
    received_timestamp VARCHAR,
    answered_timestamp VARCHAR,
    completed_timestamp VARCHAR,
    call_type VARCHAR,
    priority_level VARCHAR,
    region VARCHAR,
    channel VARCHAR,
    caller_language VARCHAR,
    disposition VARCHAR,
    abandoned_flag VARCHAR,
    transferred_flag VARCHAR,
    operator_id VARCHAR,
    service_target_seconds VARCHAR,
    loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

DESCRIBE TABLE raw_calls;