from airflow.providers.google.cloud.transfers.gcs_to_bigquery import (
    GCSToBigQueryOperator as BaseGCSToBigQueryOperator,
)
from google.cloud import storage
from airflow.exceptions import AirflowSkipException
from airflow.utils.log.logging_mixin import LoggingMixin
from helpers.connection import MySQLConnection, PostgreSQLConnection, GCPConnection

class GCSToBigQueryOperator(BaseGCSToBigQueryOperator, LoggingMixin):
    """
    Custom GCSToBigQueryOperator that:
    1. Checks if source files exist in GCS before loading
    2. Automatically fetches BigQuery schema from source database if not provided
    3. Supports both MySQL and PostgreSQL sources
    """  
    def __init__(
        self,
        schema_fields=None,
        src_conn_id=None,
        src_schema_name=None,
        src_table_name=None,
        src_source_type=None,  # "mysql" or "postgresql"
        *args,
        **kwargs,
    ):
        """
        Initialize GCSToBigQueryOperator.
        
        Args:
            schema_fields: BigQuery schema fields (optional, will be fetched if None).
            src_conn_id: Source database connection ID.
            src_schema_name: Source database schema name.
            src_table_name: Source database table name.
            src_source_type: Source database type ("mysql" or "postgresql").
        """
        self.schema_fields = schema_fields
        self.src_conn_id = src_conn_id
        self.src_schema_name = src_schema_name
        self.src_table_name = src_table_name
        self.src_source_type = src_source_type
        super().__init__(*args, **kwargs)

    def execute(self, context=None):
        """
        Execute GCS to BigQuery load with file existence check and dynamic schema fetching.
        
        Process:
        1. Render Jinja templates in source_objects (if any)
        2. Check if all source files exist in GCS bucket
        3. If files don't exist, skip task (AirflowSkipException)
        4. If schema_fields not provided, fetch from source database
        5. Call parent execute() to perform the load
        """
        # Render Jinja templates in source_objects before checking file existence
        # BaseGCSToBigQueryOperator has source_objects in template_fields
        self.render_template_fields(context)
        
        # Check if all source files exist in GCS using GCPConnection
        gcp_connection = GCPConnection(connection_id=self.gcp_conn_id)
        gcs_hook = gcp_connection.get_gcs_hook()
        client = storage.Client(credentials=gcs_hook.get_credentials())
        bucket = client.bucket(self.bucket)

        for source_object in self.source_objects:
            blob = bucket.blob(source_object)
            if not blob.exists():
                self.log.info(
                    f"File {source_object} not found in bucket {self.bucket}. Skipping task."
                )
                raise AirflowSkipException(
                    f"File {source_object} not found in bucket {self.bucket}."
                )

        self.log.info(
            f"All files {self.source_objects} found in bucket {self.bucket}. "
            f"Proceeding with loading to BigQuery."
        )

        # Fetch schema from source database if not provided
        if self.schema_fields is None:
            if not all([self.src_conn_id, self.src_schema_name, self.src_table_name, self.src_source_type]):
                raise ValueError(
                    "schema_fields not provided and missing required parameters: "
                    "src_conn_id, src_schema_name, src_table_name, src_source_type"
                )
            
            self.log.info(
                f"Fetching BigQuery schema dynamically from {self.src_source_type} source."
            )
            
            # Get appropriate connection based on source type
            if self.src_source_type == "mysql":
                connection = MySQLConnection(connection_id=self.src_conn_id)
            elif self.src_source_type in ["postgresql", "postgres"]:
                connection = PostgreSQLConnection(connection_id=self.src_conn_id)
            else:
                raise ValueError(f"Unsupported source_type: {self.src_source_type}")
            
            # Fetch BigQuery schema from source database
            self.schema_fields = connection.get_bigquery_schema(
                schema_name=self.src_schema_name,
                table_name=self.src_table_name
            )
            
            self.log.info(f"Fetched schema with {len(self.schema_fields)} fields.")

        # Call parent execute() to perform the actual load
        return super().execute(context)

