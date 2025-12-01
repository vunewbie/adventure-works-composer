import polars as pl
import pymysql
from datetime import datetime, timezone
from tempfile import NamedTemporaryFile
from typing import Any
from airflow.models import Variable
from airflow.utils.helpers import render_template
from airflow.utils.log.logging_mixin import LoggingMixin
from helpers.utils import convert_mysql_to_polars

class MySQLToGCSOperator(LoggingMixin):
    """
    Extract data from MySQL, convert to Polars DataFrame, and upload as Parquet to GCS.
    Similar to PostgreSQLToGCSOperator but uses MySQL-specific type mapping.
    """

    def __init__(
        self,
        dag_id: str,
        cursor: Any,
        query: str,
        gcs_bucket_name: str,
        gcs_file_name: str,
        gcs_hook: Any,
    ):
        self.dag_id = dag_id
        self.cursor = cursor
        self.query = query
        self.gcs_bucket_name = gcs_bucket_name
        self.gcs_file_name = gcs_file_name
        self.gcs_hook = gcs_hook

    def execute(self, context=None):
        # Render Jinja template in gcs_file_name if context is provided
        if context:
            self.gcs_file_name = render_template(self.gcs_file_name, context)
            self.log.info("Rendered GCS file name: %s", self.gcs_file_name)
        
        self.log.info("Executing extract query: %s", self.query)
        self.cursor.execute(self.query)
        rows = self.cursor.fetchall()

        if not rows:
            self.log.info("No rows returned. Setting empty flag and skipping upload.")
            Variable.set(f"{self.dag_id}_tempo_empty", "True")
            return

        pl_dtype_lookup = {
            "Int8": pl.Int8,
            "Int16": pl.Int16,
            "Int32": pl.Int32,
            "Int64": pl.Int64,
            "Float32": pl.Float32,
            "Float64": pl.Float64,
            "Boolean": pl.Boolean,
            "String": pl.Utf8,
            "Date": pl.Date,
            "Datetime": pl.Datetime,
            "Binary": pl.Binary,
        }

        # Map MySQL type_code (integer) → MySQL type name (string)
        type_code_to_name = {
            pymysql.FIELD_TYPE.TINY: "tinyint",
            pymysql.FIELD_TYPE.SHORT: "smallint",
            pymysql.FIELD_TYPE.LONG: "int",
            pymysql.FIELD_TYPE.LONGLONG: "bigint",
            pymysql.FIELD_TYPE.FLOAT: "float",
            pymysql.FIELD_TYPE.DOUBLE: "double",
            pymysql.FIELD_TYPE.DECIMAL: "decimal",
            pymysql.FIELD_TYPE.NEWDECIMAL: "decimal",
            pymysql.FIELD_TYPE.VARCHAR: "varchar",
            pymysql.FIELD_TYPE.STRING: "char",
            pymysql.FIELD_TYPE.TINY_BLOB: "tinyblob",
            pymysql.FIELD_TYPE.BLOB: "blob",
            pymysql.FIELD_TYPE.MEDIUM_BLOB: "mediumblob",
            pymysql.FIELD_TYPE.LONG_BLOB: "longblob",
            pymysql.FIELD_TYPE.DATE: "date",
            pymysql.FIELD_TYPE.DATETIME: "datetime",
            pymysql.FIELD_TYPE.TIMESTAMP: "timestamp",
            pymysql.FIELD_TYPE.TIME: "time",
        }

        schema_dict = {}
        column_names = []

        for col in self.cursor.description:
            col_name = col[0]
            column_names.append(col_name)

            type_code = col[1]
            mysql_type_name = type_code_to_name.get(type_code, "varchar")
            
            # Convert MySQL type → Polars dtype name (string)
            polars_type_name = convert_mysql_to_polars(mysql_type_name)
            
            # Map string name → Polars DataType object
            schema_dict[col_name] = pl_dtype_lookup.get(polars_type_name, pl.Utf8)

        self.log.info(
            "Extracted %s rows with %s columns: %s",
            len(rows),
            len(column_names),
            column_names,
        )
        self.log.info("Schema mapping: %s", {k: str(v) for k, v in schema_dict.items()})

        df = pl.DataFrame(rows, schema=schema_dict)

        df = df.with_columns(
            pl.lit(datetime.now(timezone.utc)).alias("_extract_date_")
        )

        Variable.set(f"{self.dag_id}_tempo_empty", "False")

        with NamedTemporaryFile(suffix=".parquet", delete=True) as tmp_file:
            df.write_parquet(
                tmp_file.name,
                compression="snappy",
                use_pyarrow=True,
            )

            with open(tmp_file.name, "rb") as f:
                parquet_bytes = f.read()

        self.gcs_hook.upload(
            bucket_name=self.gcs_bucket_name,
            object_name=self.gcs_file_name,
            data=parquet_bytes,
            mime_type="application/octet-stream",
        )

        self.log.info(
            "Successfully uploaded %s rows to gs://%s/%s",
            df.height,
            self.gcs_bucket_name,
            self.gcs_file_name,
        )

