import attr
from datetime import timedelta, datetime
from typing import List
from airflow.utils.dates import days_ago

@attr.s
class ELTModel:
    # DAG params
    schedule_interval: str = attr.ib(kw_only=True)
    max_active_runs: int = attr.ib(kw_only=True)
    catchup: bool = attr.ib(kw_only=True)
    dagrun_timeout: timedelta = attr.ib(kw_only=True)
    owner: str = attr.ib(kw_only=True)
    retries: int = attr.ib(kw_only=True)
    start_date: datetime = attr.ib(kw_only=True, default=days_ago(1))

    # Source params
    source_type: str = attr.ib(kw_only=True)
    conn_id: str = attr.ib(kw_only=True)
    schema_name: str = attr.ib(kw_only=True)

    # GCP params
    gcp_conn_id: str = attr.ib(kw_only=True)
    gcs_bucket_name: str = attr.ib(kw_only=True)
    gcp_project_id: str = attr.ib(kw_only=True)
    location: str = attr.ib(kw_only=True)
    dataset_name: str = attr.ib(kw_only=True)

    # Table params
    table_name: str = attr.ib(kw_only=True)
    primary_keys: List[str] = attr.ib(kw_only=True)
    cluster_keys: List[str] = attr.ib(kw_only=True)
    extract_conditions: List[List[str]] = attr.ib(kw_only=True)
    lookback: int = attr.ib(kw_only=True)