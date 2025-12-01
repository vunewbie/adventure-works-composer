from generators.builders.base import BaseBuilder
from helpers.connection import MySQLConnection
from operators.mysql_to_gcs import MySQLToGCSOperator

class MySQLBuilder(BaseBuilder):
    """
    Builder for MySQL → GCS → BigQuery ELT pipeline.
    Similar to PostgreSQLBuilder but uses MySQL-specific connections and operators.
    """
    @property
    def cursor(self):
        model = self.model
        return MySQLConnection(connection_id=model.conn_id).cursor

    def _get_extract_task(self, context=None):
        MySQLToGCSOperator(
            dag_id=self.dag_id,
            cursor=self.cursor,
            query=self.query,
            gcs_bucket_name=self.gcs_bucket_name,
            gcs_file_name=self.gcs_file_name,
            gcs_hook=self.gcs_hook,
        ).execute(context=context)

