import polars as pl
from datetime import datetime, timezone
from tempfile import NamedTemporaryFile
from typing import Any
from airflow.models import Variable
from airflow.utils.log.logging_mixin import LoggingMixin
from airflow.templates import SandboxedEnvironment
from helpers.utils import convert_postgresql_to_polars

class PostgreSQLToGCSOperator(LoggingMixin):
    """Extract data from PostgreSQL, convert to Polars DataFrame, and upload as Parquet to GCS."""

    def __init__(
        self, 
        dag_id,
        cursor, 
        query, 
        gcs_bucket_name, 
        gcs_file_name, 
        gcs_hook,
    ):
        self.dag_id = dag_id
        self.cursor = cursor
        self.query = query
        self.gcs_bucket_name = gcs_bucket_name
        self.gcs_file_name = gcs_file_name
        self.gcs_hook = gcs_hook

    def execute(self, context=None):
        """
        Execute PostgreSQL extraction: Query → Polars DataFrame → Parquet → GCS.
        
        Process:
        1. Execute SQL query on PostgreSQL
        2. Fetch all rows and extract column metadata
        3. Build Polars schema mapping from PostgreSQL types
        4. Create Polars DataFrame with proper schema (avoids type inference errors)
        5. Add _extract_date_ metadata column for tracking
        6. Write DataFrame to Parquet file (temporary)
        7. Upload Parquet bytes to GCS
        8. Set Airflow Variable to track if data is empty
        """
        # Render Jinja template in gcs_file_name if context is provided
        if context:
            env = SandboxedEnvironment()
            template = env.from_string(self.gcs_file_name)
            rendered = template.render(**context)
            self.gcs_file_name = rendered
            self.log.info("Rendered GCS file name: %s", self.gcs_file_name)
        
        # Execute query and fetch all rows
        self.log.info("Executing extract query: %s", self.query)
        self.cursor.execute(self.query)
        rows = self.cursor.fetchall()
        
        # Handle empty result set
        if not rows:
            self.log.info("No rows returned. Setting empty flag and skipping upload.")
            Variable.set(f"{self.dag_id}_tempo_empty", "True")
            return
        
        # Map Polars dtype string names to DataType objects
        pl_dtype_lookup = {
            "Int8": pl.Int8,
            "Int16": pl.Int16,
            "Int32": pl.Int32,
            "Int64": pl.Int64,
            "Float32": pl.Float32,
            "Float64": pl.Float64,
            "Boolean": pl.Boolean,
            "String": pl.Utf8,  # Polars uses Utf8 for strings
            "Date": pl.Date,
            "Datetime": pl.Datetime,
            "Binary": pl.Binary,
        }
        
        # Build schema dict: {column_name: pl.DataType}
        schema_dict = {}
        column_names = []
        string_column_indices = []  # Track columns that should be strings
        
        for idx, col in enumerate(self.cursor.description):
            # Extract column name
            col_name = col.name if hasattr(col, "name") else col[0]
            column_names.append(col_name)
            
            # Extract PostgreSQL type display (e.g., "integer", "varchar", "timestamp")
            type_display = (
                col.type_display if hasattr(col, "type_display") else str(col[1])
            )
            
            # Convert PostgreSQL type → Polars dtype name (string)
            polars_type_name = convert_postgresql_to_polars(type_display)
            
            # Map string name → Polars DataType object and store in schema
            schema_dict[col_name] = pl_dtype_lookup.get(polars_type_name, pl.Utf8)
            
            # Track columns that are mapped to String but might have Python objects
            if polars_type_name == "String":
                string_column_indices.append(idx)
        
        # Convert Python date/integer objects to string if schema is String
        if string_column_indices and rows:
            from datetime import date, datetime as dt
            converted_rows = []
            for row in rows:
                converted_row = list(row)
                for idx in string_column_indices:
                    value = converted_row[idx]
                    # Convert date/datetime objects to string
                    if isinstance(value, (date, dt)):
                        converted_row[idx] = value.isoformat() if hasattr(value, 'isoformat') else str(value)
                    # Convert other non-string types to string
                    elif value is not None and not isinstance(value, str):
                        converted_row[idx] = str(value)
                converted_rows.append(tuple(converted_row))
            rows = converted_rows
        
        self.log.info(
            "Extracted %s rows with %s columns: %s", 
            len(rows), 
            len(column_names), 
            column_names
        )
        self.log.info("Schema mapping: %s", {k: str(v) for k, v in schema_dict.items()})

        # Create Polars DataFrame with predefined schema
        df = pl.DataFrame(rows, schema=schema_dict, orient="row")
        
        # Add metadata column _extract_date_ for tracking extraction timestamp
        df = df.with_columns(
            pl.lit(datetime.now(timezone.utc)).alias("_extract_date_")
        )
        
        # Set Variable to track that data exists (not empty)
        Variable.set(f"{self.dag_id}_tempo_empty", "False")
        
        # Write DataFrame to temporary Parquet file
        with NamedTemporaryFile(suffix=".parquet", delete=True) as tmp_file:
            df.write_parquet(
                tmp_file.name,
                compression="snappy",
                use_pyarrow=True,
            )
            
            # Read file bytes for GCS upload
            with open(tmp_file.name, "rb") as f:
                parquet_bytes = f.read()
        
        # Upload Parquet bytes to GCS
        self.gcs_hook.upload(
            bucket_name=self.gcs_bucket_name,
            object_name=self.gcs_file_name,
            data=parquet_bytes,
            mime_type="application/octet-stream",  # Binary file type
        )
        
        self.log.info(
            "Successfully uploaded %s rows to gs://%s/%s",
            df.height,
            self.gcs_bucket_name,
            self.gcs_file_name,
        )
            