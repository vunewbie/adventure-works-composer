from airflow.utils.log.logging_mixin import LoggingMixin
from airflow.decorators import task
from airflow.models import DAG, Variable
from airflow.utils.dates import days_ago
from airflow.utils.trigger_rule import TriggerRule
from helpers.connection import GCPConnection, MySQLConnection, PostgreSQLConnection
from helpers.utils import get_hours_ago

class BaseBuilder(LoggingMixin):
    """Base builder for building ELT DAGs for all source types."""
    def __init__(self, model, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.model = model

    @property
    def dag_id(self):
        model = self.model
        return "__".join(
            [
                "elt",
                model.schema_name,
                model.table_name,
            ]
        )

    @property
    def dag_tags(self):
        model = self.model
        return [
            "elt",
            model.source_type,
            model.schema_name,
            model.table_name,
        ]

    @property
    def gcs_bucket_name(self):
        return self.model.gcs_bucket_name

    @property
    def gcs_hook(self):
        return GCPConnection(connection_id=self.model.gcp_conn_id).get_gcs_hook()

    @property
    def is_extracted_full(self):
        model = self.model
        return model.extract_conditions is None or len(model.extract_conditions) == 0

    def _gen_dag_params(self):
        model = self.model
        return {
            "dag_id": self.dag_id,
            "schedule_interval": model.schedule_interval,
            "max_active_runs": model.max_active_runs,
            "catchup": model.catchup,
            "dagrun_timeout": model.dagrun_timeout,
            "start_date": model.start_date,
            "default_args": {
                "owner": model.owner,
                "retries": model.retries,
            },
            "tags": self.dag_tags,
        }

    def _gen_gcs_file_name(self):
        """Ex: elt/human_resources/department/2025-11-30"""
        model = self.model
        gcs_file_name = "{dag_type}/{schema_name}/{table_name}/{partition}".format(
            dag_type="elt",
            schema_name=model.schema_name,
            table_name=model.table_name,
            partition="{{ data_interval_start.format('YYYY-MM-DD') }}",
        )
        return gcs_file_name

    @property
    def gcs_file_name(self):
        return self._gen_gcs_file_name()

    def _gen_extract_query_statement(self):
        """
        Generate SQL query for extraction with incremental loading support.
        
        Supports incremental extraction using extract_conditions.
        Placeholder "replace_variable_key" is replaced with last extraction
        timestamp from Airflow Variable.
        
        Returns:
            str: Complete SELECT query with optional WHERE clause.
            Ex:
                SELECT *
                FROM human_resources.department
                WHERE modified_date >= '2025-01-01 00:00:00'
        """
        model = self.model
        select_statement = "SELECT *\n"
        from_statement = f"FROM {model.schema_name}.{model.table_name}"

        # Full extract if no conditions specified
        if self.is_extracted_full:
            where_statement = ""
        else:
            conditions = []
            for condition in model.extract_conditions:
                key, operator, value = condition

                # Replace placeholder with last extraction timestamp
                if value == "replace_variable_key":
                    replaced_value = Variable.get(
                        f"{self.dag_id}_last_extraction", default_var=days_ago(1)
                    )
                    value = (
                        f"'{replaced_value}'"
                        if replaced_value is not None
                        else f"'{days_ago(1)}'"
                    )

                conditions.append(f"{key} {operator} {value}")

            where_statement = f"WHERE {' AND '.join(conditions)}"

        return f"{select_statement}\n{from_statement}\n{where_statement}"

    @property
    def query(self):
        """Get generated extract query."""
        return self._gen_extract_query_statement()
    
    def _get_extract_task(self, context=None):
        """Create extract task (source → GCS). Must be implemented by subclasses."""
        model = self.model

        raise NotImplementedError(f"Not implemented extract task for {model.source_type} source.")

    def _get_load_task(self, context=None):
        """
        Execute load task (GCS → BigQuery pre_raw layer).
        
        Process:
        1. Check if source file exists in GCS
        2. Automatically fetch BigQuery schema from source database
        3. Load Parquet file to BigQuery staging table (dataset__pre_raw)
        
        Args:
            context: Airflow execution context (optional).
            
        Returns:
            None: Operator executes the load operation.
        """
        from operators.gcs_to_bigquery import GCSToBigQueryOperator
        
        model = self.model
        
        # Destination table: dataset__pre_raw.{dataset_name}__{table_name}
        destination_table = f"dataset__pre_raw.{model.dataset_name}__{model.table_name}"
        
        # Create and execute GCSToBigQueryOperator
        # Schema will be fetched automatically if not provided
        GCSToBigQueryOperator(
            gcp_conn_id=model.gcp_conn_id,
            bucket=model.gcs_bucket_name,
            source_objects=[self.gcs_file_name],  # Jinja template will be rendered
            destination_project_dataset_table=destination_table,
            source_format="PARQUET",
            write_disposition="WRITE_APPEND",
            schema_fields=None,  # Will be fetched automatically from source database
            schema_update_options=["ALLOW_FIELD_ADDITION"],
            time_partitioning={
                "field": "_extract_date_",
                "type": "HOUR",
            },
            cluster_fields=model.primary_keys if model.primary_keys else None,
            location=model.location,
            # Parameters for automatic schema fetching
            src_conn_id=model.conn_id,
            src_schema_name=model.schema_name,
            src_table_name=model.table_name,
            src_source_type=model.source_type,
        ).execute(context=context)

    def _init_dataset(self):
        """
        Initialize BigQuery raw dataset and table if not exists.
        
        Creates:
        - Dataset: raw__{dataset_name}
        - Table: tbl__{table_name} with schema from pre_raw, partitioning, and clustering
        """
        model = self.model
        bq_hook = GCPConnection(connection_id=model.gcp_conn_id).get_bq_hook()
        
        # Check if pre_raw table exists
        if bq_hook.table_exists(
            dataset_id="dataset__pre_raw",
            table_id=f"{model.dataset_name}__{model.table_name}",
        ):
            # Create raw dataset if not exists
            bq_hook.create_empty_dataset(
                dataset_id=f"raw__{model.dataset_name}",
                location=model.location,
                exists_ok=True,
            )
            
            # Get schema from pre_raw table
            pre_raw_schema_fields = bq_hook.get_schema(
                dataset_id="dataset__pre_raw",
                table_id=f"{model.dataset_name}__{model.table_name}",
            ).get("fields", [])
            
            # Create raw table with schema, partitioning, and clustering
            bq_hook.create_empty_table(
                dataset_id=f"raw__{model.dataset_name}",
                table_id=f"tbl__{model.table_name}",
                schema_fields=pre_raw_schema_fields,
                time_partitioning={
                    "type": "DAY",
                    "field": "_extract_date_",
                },
                cluster_fields=model.cluster_keys if model.cluster_keys else None,
            )
            
            # Mark as initialized
            Variable.set(f"{self.dag_id}_is_inited", "True")
            self.log.info(f"Initialized raw dataset and table: raw__{model.dataset_name}.tbl__{model.table_name}")

    def _get_merge_task(self, context=None):
        """
        Merge data from pre_raw to raw layer with deduplication and upsert.
        
        Process:
        1. Skip if no data was extracted
        2. Initialize raw dataset/table if not done
        3. Build MERGE SQL query with deduplication
        4. Execute MERGE query in BigQuery
        
        Args:
            context: Airflow execution context (optional).
        """
        model = self.model
        bq_hook = GCPConnection(connection_id=model.gcp_conn_id).get_bq_hook()
        
        # Skip merge if no data was extracted
        if Variable.get(f"{self.dag_id}_tempo_empty", "False") == "True":
            self.log.info("No data extracted, skipping merge task.")
            return
        
        # Initialize raw dataset/table if not done
        if not Variable.get(f"{self.dag_id}_is_inited", None):
            self._init_dataset()
        
        # Get source schema fields
        if model.source_type == "mysql":
            connection = MySQLConnection(connection_id=model.conn_id)
        elif model.source_type in ["postgresql", "postgres"]:
            connection = PostgreSQLConnection(connection_id=model.conn_id)
        else:
            raise ValueError(f"Unsupported source_type: {model.source_type}")
        
        source_schema_fields = connection.get_source_table_columns(
            schema_name=model.schema_name,
            table_name=model.table_name
        )
        
        # Build SQL components
        # A) Extract condition: only recent data (2 hours)
        extract_condition_stm = (
            "_extract_date_ >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 HOUR)"
        )
        
        # B) Partition key for ROW_NUMBER (dedup)
        partition_keys = model.primary_keys if model.primary_keys else source_schema_fields
        partition_key_stm = ", ".join([f"`{key}`" for key in partition_keys])
        
        # C) Merge key (ON clause)
        merge_key_stm = " AND ".join([
            f"_bq_destination.`{key}` = _bq_source.`{key}`"
            for key in partition_keys
        ])
        
        # D) INSERT statement (WHEN NOT MATCHED)
        all_columns = source_schema_fields + ["_extract_date_"]
        insert_columns_stm = ", ".join([f"`{col}`" for col in all_columns])
        insert_values_stm = ", ".join([f"_bq_source.`{col}`" for col in all_columns])
        merge_not_matched_stm = f"""
            INSERT ({insert_columns_stm})
            VALUES ({insert_values_stm})
        """
        
        # E) UPDATE statement (WHEN MATCHED) - exclude primary keys
        update_fields = [
            f"_bq_destination.`{key}` = _bq_source.`{key}`"
            for key in source_schema_fields
            if key not in (model.primary_keys if model.primary_keys else [])
        ]
        merge_matched_stm = ", ".join(update_fields) if update_fields else ""
        
        # F) Optimize with cluster keys (if configured)
        filter_date_stm = ""
        if model.cluster_keys:
            filter_date_stm = f"""
                DECLARE date_list ARRAY<DATE>;
                SET date_list = (
                    SELECT ARRAY_AGG(DISTINCT CAST({model.cluster_keys[0]} AS DATE))
                    FROM `dataset__pre_raw.{model.dataset_name}__{model.table_name}`
                    WHERE {extract_condition_stm}
                );
            """
            merge_key_stm = (
                merge_key_stm +
                f" AND CAST(_bq_destination.`{model.cluster_keys[0]}` AS DATE) IN UNNEST(date_list)"
            )
        
        # G) Assemble final MERGE SQL
        query_stm = f"""
            BEGIN 
            {filter_date_stm}

            MERGE INTO `raw__{model.dataset_name}.tbl__{model.table_name}` AS _bq_destination
            USING (
                SELECT * 
                FROM `dataset__pre_raw.{model.dataset_name}__{model.table_name}`
                WHERE {extract_condition_stm}
                QUALIFY ROW_NUMBER() OVER (PARTITION BY {partition_key_stm} ORDER BY `_extract_date_` DESC) = 1
            ) AS _bq_source

            ON {merge_key_stm}

            WHEN MATCHED THEN UPDATE
            SET _bq_destination.`_extract_date_` = _bq_source.`_extract_date_`
                {f", {merge_matched_stm}" if merge_matched_stm else ""}

            WHEN NOT MATCHED THEN
            {merge_not_matched_stm};

            END;
        """
        
        # Execute MERGE query
        self.log.info(f"Executing MERGE query for {model.dataset_name}.{model.table_name}")
        bq_hook.get_client().query(query_stm).result()
        self.log.info("MERGE completed successfully")

    def _set_last_extracted_time(self, context=None):
        """
        Update last extraction timestamp for incremental loading.
        
        Queries the maximum value of the extraction field from raw table
        (within last 3 days) and subtracts lookback seconds.
        Sets Airflow Variable for next incremental extraction.
        
        Args:
            context: Airflow execution context (optional).
        """
        model = self.model
        bq_hook = GCPConnection(connection_id=model.gcp_conn_id).get_bq_hook()
        
        # Get extraction field from first condition
        # Note: Currently supports only 1 condition
        extracted_key = model.extract_conditions[0][0] if model.extract_conditions else None
        if not extracted_key:
            self.log.warning("No extract_conditions found, skipping last extraction time update.")
            return
        
        # If no data extracted, set to 1 hour ago (fallback)
        if Variable.get(f"{self.dag_id}_tempo_empty", "False") == "True":
            Variable.set(
                f"{self.dag_id}_last_extraction",
                get_hours_ago(1),
            )
            self.log.info(f"Set last extraction time to 1 hour ago (no data extracted)")
            return
        
        # Query last extraction from recent data (3 days)
        # Subtract lookback seconds from max timestamp
        condition_stm = (
            "DATE(`_extract_date_`) >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)"
        )
        select_stm = (
            f'FORMAT_TIMESTAMP("%F %T", '
            f'TIMESTAMP_SUB(MAX(`{extracted_key}`), INTERVAL {model.lookback} SECOND)) '
            f'AS {extracted_key}'
        )
        
        query_stm = (
            f"SELECT {select_stm}\n"
            f"FROM `raw__{model.dataset_name}.tbl__{model.table_name}`\n"
            f"WHERE {condition_stm}\n"
        )
        
        # Execute query and get result
        results = bq_hook.get_pandas_df(sql=query_stm)
        
        # Update variable with last extraction time or fallback
        last_extraction_time = (
            results[extracted_key].iloc[0] if not results.empty else get_hours_ago(1)
        )
        Variable.set(f"{self.dag_id}_last_extraction", last_extraction_time)
        self.log.info(f"Set last extraction time: {last_extraction_time}")

    def build_dag(self):
        """
        Build DAG using TaskFlow API with extract -> load -> merge -> set_last_extracted tasks.
        
        Returns:
            DAG: Airflow DAG instance with complete ELT pipeline.
        """        
        dag = DAG(**self._gen_dag_params())

        # Extract task: source database → GCS
        @task(dag=dag, task_id="extract")
        def extract_task(context=None):
            """Extract data from source to GCS."""
            return self._get_extract_task(context=context)
        
        # Load task: GCS → BigQuery pre_raw
        @task(dag=dag, task_id="load")
        def load_task(context=None):
            """Load data from GCS to BigQuery pre_raw layer."""
            return self._get_load_task(context=context)
        
        # Merge task: pre_raw → raw (deduplication and upsert)
        @task(dag=dag, task_id="merge")
        def merge_task(context=None):
            """Merge data from pre_raw to raw layer with deduplication."""
            return self._get_merge_task(context=context)
        
        # Set last extraction time task (only for incremental loading)
        if not self.is_extracted_full:
            @task(
                dag=dag,
                task_id="set_last_extracted",
                trigger_rule=TriggerRule.NONE_FAILED,
            )
            def set_last_extracted_task(context=None):
                """Update last extraction timestamp for incremental loading."""
                return self._set_last_extracted_time(context=context)
            
            # Main pipeline: extract -> load -> merge -> set_last_extracted
            extract_task() >> load_task() >> merge_task() >> set_last_extracted_task()
        else:
            # Full extract: extract -> load -> merge (no timestamp update)
            extract_task() >> load_task() >> merge_task()
        
        # Return tuple (dag, dag_id) for compatibility with load_dags optimization
        return dag, self.dag_id