import yaml
import os
from datetime import timedelta
from airflow.utils.log.logging_mixin import LoggingMixin
from airflow.exceptions import AirflowException
from generators.model import ELTModel
from generators.builders.mysql import MySQLBuilder
from generators.builders.postgresql import PostgreSQLBuilder

class DAGGenerator(LoggingMixin):
    """
    DAG generator for generating DAGs from YAML configuration files.
    Dynamically creates ELT DAGs based on YAML configs for each table.
    """
    def __init__(
        self,
        base_config_path: str,
        *args,
        **kwargs
    ):
        super().__init__()
        self.base_config_path = base_config_path

    def _load_config_file_paths(self):
        """Load .yaml file paths from the base configs path to a list"""
        files_name = os.listdir(self.base_config_path)

        yaml_file_paths = [
            os.path.join(self.base_config_path, yaml_file)
            for yaml_file in files_name
            if yaml_file.endswith(".yaml") or yaml_file.endswith(".yml")
        ]
    
        return yaml_file_paths

    def _load_configs_to_dict(self, configs_file_path):
        """
        Load configs from .yaml file to a dictionary
        Ex: {"general": {"dag_configs": {...}, "source_configs": {...}, "gcp_configs": {...}, "default_table": {...}}, "tables": [...]}
        """
        with open(configs_file_path, "r") as file_configs:
            return yaml.safe_load(file_configs)

    def _build_dags_configs(self, configs_dict):
        """
        Extracts and builds DAG-level configurations from YAML dictionary.
        Flattens nested structure from YAML to a dictionary.
        """
        general_configs = configs_dict.get("general", {})
        dag_configs = general_configs.get("dag_configs", {})
        source_configs = general_configs.get("source_configs", {})
        gcp_configs = general_configs.get("gcp_configs", {})
        default_table_configs = general_configs.get("default_table", {})

        return {
            # DAG configs
            "schedule_interval": dag_configs.get("schedule_interval"),
            "max_active_runs": int(dag_configs.get("max_active_runs")),
            "catchup": dag_configs.get("catchup"),
            "dagrun_timeout": timedelta(seconds=int(dag_configs.get("dagrun_timeout"))),
            "owner": dag_configs.get("owner"),
            "retries": int(dag_configs.get("retries")),

            # Source configs
            "source_type": source_configs.get("source_type"),
            "conn_id": source_configs.get("conn_id"),
            "schema_name": source_configs.get("schema_name"),
            
            # GCP configs
            "gcp_conn_id": gcp_configs.get("gcp_conn_id"),
            "gcs_bucket_name": gcp_configs.get("gcs_bucket_name"),
            "gcp_project_id": gcp_configs.get("gcp_project_id"),
            "location": gcp_configs.get("location"),
            "dataset_name": gcp_configs.get("dataset_name"),
            
            # Default table configs
            "is_disabled": default_table_configs.get("is_disabled"),
            "extract_conditions": default_table_configs.get("extract_conditions"),
            "lookback": int(default_table_configs.get("lookback")),
            "primary_keys": default_table_configs.get("primary_keys"),
            "cluster_keys": default_table_configs.get("cluster_keys"),
        }

    def _build_table_configs(self, table_configs, dags_configs):
        """
        Builds table-specific configurations with fallback to default values.
        Args:
            table_configs: Table-specific config from YAML "tables" list.
            dags_configs: Default configs from _build_dags_configs().
            
        Returns:
            dict: Table configurations with defaults applied.
        """
        if "table_name" not in table_configs:
            raise AirflowException("Missing required field `table_name` in table configs.")

        def _get_with_default(key):
            """Helper to get value from table_configs or fallback to dags_configs."""
            value = table_configs.get(key)
            if value is None:
                return dags_configs.get(key)
            return value

        return {
            "table_name": table_configs["table_name"],
            "primary_keys": _get_with_default("primary_keys"),
            "cluster_keys": _get_with_default("cluster_keys"),
            "extract_conditions": _get_with_default("extract_conditions"),
            "lookback": _get_with_default("lookback"),
            "is_disabled": _get_with_default("is_disabled"),
        }

    def _build_dag_configs(self, dags_configs, table_configs):
        """Build a DAG config from the dags configs and table configs"""
        return {
            # DAG configs
            "schedule_interval": dags_configs.get("schedule_interval"),
            "max_active_runs": dags_configs.get("max_active_runs"),
            "catchup": dags_configs.get("catchup"),
            "dagrun_timeout": dags_configs.get("dagrun_timeout"),
            "owner": dags_configs.get("owner"),
            "retries": dags_configs.get("retries"),

            # Source configs
            "source_type": dags_configs.get("source_type"),
            "conn_id": dags_configs.get("conn_id"),
            "schema_name": dags_configs.get("schema_name"),

            # GCP configs
            "gcp_conn_id": dags_configs.get("gcp_conn_id"),
            "gcs_bucket_name": dags_configs.get("gcs_bucket_name"),
            "gcp_project_id": dags_configs.get("gcp_project_id"),
            "location": dags_configs.get("location"),
            "dataset_name": dags_configs.get("dataset_name"),

            # Table configs
            "table_name": table_configs.get("table_name"),
            "primary_keys": table_configs.get("primary_keys"),
            "cluster_keys": table_configs.get("cluster_keys"),
            "extract_conditions": table_configs.get("extract_conditions"),
            "lookback": table_configs.get("lookback"),
        }

    def _get_builder(self, model):
        """Get appropriate builder based on source_type"""
        if model.source_type == "mysql":
            return MySQLBuilder(model=model)
            
        elif model.source_type == "postgresql":
            return PostgreSQLBuilder(model=model)
            
        else:
            raise AirflowException(f"Unsupported source_type: {model.source_type}.")

    def _get_airflow_params(self):
        """
        Detects Airflow execution context to optimize DAG loading.
        
        Returns:
            dict: Airflow execution context with keys:
                - "subcommmand": Subcommand being executed (e.g., "run")
                - "dag_id": DAG ID if running specific task
            Ex: {"subcommmand": "run", "dag_id": "elt__human_resources__department"}
        """
        import sys
        from setproctitle import getproctitle

        subcommand = None
        dag_id = None

        argv = sys.argv

        # Extract original CLI args from process title when running under task supervisor
        proctitle = getproctitle()
        if "airflow" in proctitle and "task supervisor" in proctitle:
            import json

            argv_json = proctitle.replace("airflow task supervisor: ", "").replace(
                "'", '"'
            )
            argv = json.loads(argv_json)

        # Parse CLI arguments to detect execution context
        if len(argv) >= 4 and argv[0].endswith("airflow"):
            # Ex: argv = ["airflow", "tasks", "run", "elt__human_resources__department", "extract", "2025-01-01"]
            if argv[1] == "tasks" and argv[2] == "run":
                subcommand = "run"
                dag_id = argv[3]

        if dag_id:
            return {
                "subcommmand": subcommand,
                "dag_id": dag_id,
            }

        return {}

    def load_dags(self, __globals__):
        """
        Loads and registers DAGs from YAML configurations.
        Optimizes loading for task execution vs scheduler mode.
        
        Process:
        1. Build all DAGs into temporary list
        2. Detect Airflow execution context (task run vs scheduler/webserver)
        3. Register only necessary DAGs based on context
        """
        # Find all YAML config files
        configs_file_paths = self._load_config_file_paths()

        # Build all DAGs into temporary list
        tuple_temp = []
        for configs_file_path in configs_file_paths:
            # Load and parse YAML configuration
            configs_dict = self._load_configs_to_dict(configs_file_path)
            dags_configs = self._build_dags_configs(configs_dict)

            # Process each table in the YAML file
            for table_configs in configs_dict.get("tables", []):
                table_configs = self._build_table_configs(table_configs, dags_configs)

                # Skip disabled tables
                if not table_configs.get("is_disabled"):
                    # Merge configs and create model
                    dag_configs = self._build_dag_configs(dags_configs, table_configs)
                    model = ELTModel(**dag_configs)
                    
                    # Build DAG using appropriate builder
                    builder = self._get_builder(model)
                    dag_tuple = builder.build_dag()
                    
                    # Store DAG tuple (dag_id, dag) in temporary list
                    if dag_tuple:
                        dag, dag_id = dag_tuple
                        tuple_temp.append((dag_id, dag))
                        self.log.info(f"Built DAG: {dag_id}")

        # Performance optimization: load only specific DAG during task execution
        airflow_args = self._get_airflow_params()

        if airflow_args.get("subcommmand") == "run":
            # Task execution mode: only load the DAG being executed
            run_dag_id = airflow_args.get("dag_id")
            self.log.info(f"Task execution mode detected. Loading only DAG: {run_dag_id}")
            
            for dag_id, dag in tuple_temp:
                if run_dag_id == dag_id:
                    __globals__[dag_id] = dag
                    self.log.info(f"Registered DAG for task execution: {dag_id}")
                    break
        else:
            # Scheduler/Webserver mode: load all DAGs
            self.log.info(f"Scheduler/Webserver mode. Loading all {len(tuple_temp)} DAGs")
            
            for dag_id, dag in tuple_temp:
                __globals__[dag_id] = dag
                self.log.info(f"Registered DAG: {dag_id}")

    

            