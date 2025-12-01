from generators.builders.base import BaseBuilder
from helpers.connection import PostgreSQLConnection
from operators.postgresql_to_gcs import PostgreSQLToGCSOperator

class PostgreSQLBuilder(BaseBuilder):
    """Builder for PostgreSQL → GCS → BigQuery ELT pipeline."""
    @property
    def cursor(self):
        model = self.model
        return PostgreSQLConnection(connection_id=model.conn_id).cursor

    def _get_extract_task(self, context=None):
        PostgreSQLToGCSOperator(
            dag_id=self.dag_id,
            cursor=self.cursor,
            query=self.query,
            gcs_bucket_name=self.gcs_bucket_name,
            gcs_file_name=self.gcs_file_name,
            gcs_hook=self.gcs_hook,
        ).execute(context=context)