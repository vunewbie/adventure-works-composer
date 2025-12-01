from airflow.utils.log.logging_mixin import LoggingMixin
from airflow.providers.postgres.hooks.postgres import PostgresHook
from airflow.providers.mysql.hooks.mysql import MySqlHook
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from helpers.utils import convert_mysql_to_polars, convert_postgresql_to_polars, convert_polars_to_bq

class MySQLConnection(LoggingMixin):
    """MySQL connection for extracting data from master data database"""
    def __init__(
        self,
        connection_id: str,
        *args,
        **kwargs
    ):
        super().__init__()
        self.connection_id = connection_id
        self.hook = MySqlHook(mysql_conn_id=connection_id)
        self.log.info(f"Initialized MySQL connection for {connection_id}")

    @property
    def conn(self):
        return self.hook.get_conn()

    @property
    def cursor(self):
        return self.conn.cursor()

    def get_source_table_columns(self, schema_name: str, table_name: str) -> list[str]:
        query = """
            SELECT COLUMN_NAME
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = %s
            AND TABLE_NAME = %s
            ORDER BY ORDINAL_POSITION
        """
        cursor = self.cursor
        cursor.execute(query, (schema_name, table_name))
        columns = [row[0] for row in cursor.fetchall()]
        cursor.close()
        return columns
    
    def get_bigquery_schema(self, schema_name: str, table_name: str) -> list[dict]:
        query = """
            SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = %s
            AND TABLE_NAME = %s
            ORDER BY ORDINAL_POSITION
        """
        cursor = self.cursor
        cursor.execute(query, (schema_name, table_name))
        columns_info = cursor.fetchall()
        cursor.close()
        
        schema_fields = []
        for col_name, data_type, is_nullable in columns_info:
            # Map MySQL type → Polars dtype → BigQuery type
            polars_type = convert_mysql_to_polars(data_type)
            bq_type = convert_polars_to_bq(polars_type)
            schema_fields.append({
                "name": col_name,
                "type": bq_type,
                "mode": "NULLABLE" if is_nullable == "YES" else "REQUIRED"
            })

        # Add metadata column for tracking extraction timestamp
        schema_fields.append({
            "name": "_extract_date_",
            "type": "TIMESTAMP",
            "mode": "NULLABLE",
        })

        self.log.info(f"BigQuery schema for {schema_name}.{table_name}: {schema_fields}")
        return schema_fields

class PostgreSQLConnection(LoggingMixin):
    """PostgreSQL connection for extracting data from master data database"""
    def __init__(
        self,
        connection_id: str,
        *args,
        **kwargs
    ):
        super().__init__()
        self.connection_id = connection_id
        self.hook = PostgresHook(postgres_conn_id=connection_id)
        self.log.info(f"Initialized PostgreSQL connection for {connection_id}")

    @property
    def conn(self):
        return self.hook.get_conn()

    @property
    def cursor(self):
        return self.conn.cursor()

    def get_source_table_columns(self, schema_name: str, table_name: str) -> list[str]:
        query = """
            SELECT COLUMN_NAME
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = %s
            AND TABLE_NAME = %s
            ORDER BY ORDINAL_POSITION
        """
        cursor = self.cursor
        cursor.execute(query, (schema_name, table_name))
        columns = [row[0] for row in cursor.fetchall()]
        cursor.close()
        return columns

    def get_bigquery_schema(self, schema_name: str, table_name: str) -> list[dict]:
        query = """
            SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = %s
            AND TABLE_NAME = %s
            ORDER BY ORDINAL_POSITION
        """
        cursor = self.cursor
        cursor.execute(query, (schema_name, table_name))
        columns_info = cursor.fetchall()
        cursor.close()
        schema_fields = []
        for col_name, data_type, is_nullable in columns_info:
            polars_type = convert_postgresql_to_polars(data_type)
            bq_type = convert_polars_to_bq(polars_type)
            schema_fields.append({
                "name": col_name,
                "type": bq_type,
                "mode": "NULLABLE" if is_nullable == "YES" else "REQUIRED"
            })
        
        schema_fields.append({
            "name": "_extract_date_",
            "type": "TIMESTAMP",
            "mode": "NULLABLE",
        })

        self.log.info(f"BigQuery schema for {schema_name}.{table_name}: {schema_fields}")
        return schema_fields

class GCPConnection(LoggingMixin):
    """GCP connection for loading data to BigQuery"""
    def __init__(
        self,
        connection_id: str,
        *args,
        **kwargs
    ):
        super().__init__()
        self.connection_id = connection_id

    def get_bq_hook(self):
        return BigQueryHook(
            gcp_conn_id=self.connection_id,
            use_legacy_sql=False,
            location="asia-southeast1",
        )

    def get_gcs_hook(self):
        return GCSHook(
            gcp_conn_id=self.connection_id,
        )

