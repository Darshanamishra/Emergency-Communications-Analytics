import random
from datetime import datetime, timedelta

import numpy as np
import pandas as pd


random.seed(42)
np.random.seed(42)

number_of_calls = 50000
start_date = datetime(2025, 1, 1)
end_date = datetime(2025, 12, 31, 23, 59, 59)

call_types = [
    "Police",
    "Medical",
    "Fire",
    "Traffic",
    "Public Assistance",
]

priorities = ["P1", "P2", "P3", "P4"]

regions = [
    "North",
    "South",
    "East",
    "West",
    "Central",
]

channels = ["Emergency", "Non-Emergency"]

languages = [
    "English",
    "French",
    "Punjabi",
    "Hindi",
    "Other",
]

dispositions = [
    "Dispatched",
    "Advice Provided",
    "Transferred",
    "Cancelled",
    "No Action Required",
]


def create_random_timestamp():
    total_seconds = int((end_date - start_date).total_seconds())
    random_seconds = random.randint(0, total_seconds)
    return start_date + timedelta(seconds=random_seconds)


records = []

for call_number in range(1, number_of_calls + 1):
    received_time = create_random_timestamp()

    abandoned = random.random() < 0.06

    if abandoned:
        answered_time = None
        completed_time = None
        answer_time_seconds = None
        handling_time_seconds = None
    else:
        answer_time_seconds = max(
            1,
            int(np.random.gamma(shape=2.2, scale=7)),
        )

        answered_time = received_time + timedelta(
            seconds=answer_time_seconds
        )

        handling_time_seconds = max(
            30,
            int(np.random.gamma(shape=4, scale=75)),
        )

        completed_time = answered_time + timedelta(
            seconds=handling_time_seconds
        )

    priority = random.choices(
        priorities,
        weights=[10, 25, 40, 25],
        k=1,
    )[0]

    service_target_seconds = {
        "P1": 10,
        "P2": 15,
        "P3": 20,
        "P4": 30,
    }[priority]

    transferred = False if abandoned else random.random() < 0.12

    records.append(
        {
            "call_id": f"CALL-{call_number:06d}",
            "received_timestamp": received_time,
            "answered_timestamp": answered_time,
            "completed_timestamp": completed_time,
            "call_type": random.choice(call_types),
            "priority_level": priority,
            "region": random.choice(regions),
            "channel": random.choices(
                channels,
                weights=[75, 25],
                k=1,
            )[0],
            "caller_language": random.choices(
                languages,
                weights=[75, 5, 8, 7, 5],
                k=1,
            )[0],
            "disposition": (
                "Abandoned"
                if abandoned
                else random.choice(dispositions)
            ),
            "abandoned_flag": abandoned,
            "transferred_flag": transferred,
            "operator_id": (
                None
                if abandoned
                else f"OP-{random.randint(1, 40):03d}"
            ),
            "service_target_seconds": service_target_seconds,
        }
    )


calls = pd.DataFrame(records)

# Add a few data-quality issues for validation practice
calls.loc[
    random.sample(range(len(calls)), 50),
    "call_type",
] = None

calls.loc[
    random.sample(range(len(calls)), 40),
    "region",
] = None

duplicate_rows = calls.sample(25, random_state=42)
calls = pd.concat([calls, duplicate_rows], ignore_index=True)

output_file = "data/emergency_calls.csv"
calls.to_csv(output_file, index=False)

print(f"Created {len(calls):,} rows")
print(f"Saved file to: {output_file}")
print(calls.head())