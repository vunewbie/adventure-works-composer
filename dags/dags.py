import os
from generator import DAGGenerator

def resolve_config_path():
    """Dags folder path for both airflow at localhost and composer on GCP"""
    # Composer
    dags_folder = os.environ.get("DAGS_FOLDER")
    if dags_folder:
        return os.path.join(dags_folder, "configs")

    # Airflow
    airflow_home = os.environ.get("AIRFLOW_HOME")
    if airflow_home:
        return os.path.join(airflow_home, "dags", "configs")

    return None

DAGGenerator(base_config_path=resolve_config_path()).load_dags(globals())