from datetime import timedelta
import pandas as pd
import feast.types
from feast import (Entity, Field, FeatureView, RedshiftSource,
                   ValueType, RequestSource)
from feast.on_demand_feature_view import on_demand_feature_view

zipcode = Entity(name="zipcode", value_type=ValueType.INT64)

zipcode_source = RedshiftSource(
    name='zipcode_features',
    query="SELECT * FROM spectrum.zipcode_features",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

zipcode_features = FeatureView(
    name="zipcode_features",
    entities=[zipcode],
    ttl=timedelta(days=3650),
    schema=[
        Field(name="city", dtype=feast.types.String),
        Field(name="state", dtype=feast.types.String),
        Field(name="location_type", dtype=feast.types.String),
        Field(name="tax_returns_filed", dtype=feast.types.Int64),
        Field(name="population", dtype=feast.types.Int64),
        Field(name="total_wages", dtype=feast.types.Int64),
    ],
    source=zipcode_source
)

dob_ssn = Entity(
    name="dob_ssn",
    value_type=ValueType.STRING,
    description="Date of birth and last four digits of social security number",
)

credit_history_source = RedshiftSource(
    name="credit_history",
    query="SELECT * FROM spectrum.credit_history",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

credit_history = FeatureView(
    name="credit_history",
    entities=[dob_ssn],
    ttl=timedelta(days=3650),
    schema=[
        Field(name="credit_card_due", dtype=feast.types.Int64),
        Field(name="mortgage_due", dtype=feast.types.Int64),
        Field(name="student_loan_due", dtype=feast.types.Int64),
        Field(name="vehicle_loan_due", dtype=feast.types.Int64),
        Field(name="hard_pulls", dtype=feast.types.Int64),
        Field(name="missed_payments_2y", dtype=feast.types.Int64),
        Field(name="missed_payments_1y", dtype=feast.types.Int64),
        Field(name="missed_payments_6m", dtype=feast.types.Int64),
        Field(name="bankruptcies", dtype=feast.types.Int64),
    ],
    source=credit_history_source
)

# Feature Engineering part where we add definitions for transforming categorical variables into numerical ones

person_home_ownership_request = RequestSource(
    name="person_home_ownership",
    schema=[
        Field(name="person_home_ownership", dtype=feast.types.String),
    ],
)

loan_intent_request = RequestSource(
    name="loan_intent",
    schema=[
        Field(name="loan_intent", dtype=feast.types.String),
    ],
)


@on_demand_feature_view(
    sources=[
        person_home_ownership_request
    ],
    schema=[
        Field(name='person_home_ownership_enc', dtype=feast.types.Int64),
    ]
)
def person_home_ownership(features_df: pd.DataFrame) -> pd.DataFrame:
    df = pd.DataFrame()
    d = {'RENT': 0, 'OWN': 1, "MORGAGE": 2, 'OTHER': 3}
    df['person_home_ownership_enc'] = features_df['person_home_ownership'].apply(lambda pho: d.get(pho, 3))
    return df


@on_demand_feature_view(
    sources=[
        loan_intent_request
    ],
    schema=[
        Field(name='loan_intent_enc', dtype=feast.types.Int64),
    ]
)
def loan_intent(features_df: pd.DataFrame) -> pd.DataFrame:
    df = pd.DataFrame()
    d = {'PERSONAL': 0, 'EDUCATION': 1, 'MEDICAL': 2, 'VENTURE': 3, 'HOMEIMPROVEMENT': 4, 'DEBTCONSOLIDATION': 5}
    df['loan_intent_enc'] = features_df['loan_intent'].apply(lambda pho: d.get(pho, 6))
    return df
