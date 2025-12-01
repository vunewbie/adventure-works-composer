import re
from datetime import datetime, timezone, timedelta

def convert_mysql_to_polars(source_type: str) -> str:
    """Convert MySQL data type to Polars dtype"""
    type_mapping = {
        "tinyint": "Int8",
        "smallint": "Int16",
        "mediumint": "Int32",
        "int": "Int32",
        "integer": "Int32",
        "bigint": "Int64",
        "float": "Float64",
        "double": "Float64",
        "decimal": "Float64",
        "numeric": "Float64",
        "char": "String",
        "varchar": "String",
        "text": "String",
        "longtext": "String",
        "mediumtext": "String",
        "tinytext": "String",
        "date": "Date",
        "datetime": "Datetime",
        "timestamp": "Datetime",
        "time": "String",
        "blob": "Binary",
        "binary": "Binary",
        "varbinary": "Binary",
        "longblob": "Binary",
        "mediumblob": "Binary",
        "tinyblob": "Binary",
    }
    
    find_result = source_type.find("(")
    source_type = source_type[:find_result] if find_result != -1 else source_type
    source_type = re.sub(r"\d+", "", source_type)
    source_type = source_type.lower().strip()
    
    return type_mapping.get(source_type, "String")

def convert_postgresql_to_polars(source_type: str) -> str:
    """Convert PostgreSQL data type to Polars dtype"""
    type_mapping = {
        "smallint": "Int16",
        "integer": "Int32",
        "int": "Int32",
        "bigint": "Int64",
        "serial": "Int32",
        "bigserial": "Int64",
        "real": "Float32",
        "double precision": "Float64",
        "numeric": "Float64",
        "decimal": "Float64",
        "money": "Float64",
        "boolean": "Boolean",
        "bool": "Boolean",
        "char": "String",
        "character": "String",
        "varchar": "String",
        "character varying": "String",
        "text": "String",
        "date": "Date",
        "timestamp": "Datetime",
        "timestamp without time zone": "Datetime",
        "timestamp with time zone": "Datetime",
        "timestamptz": "Datetime",
        "time": "String",
        "time without time zone": "String",
        "time with time zone": "String",
        "bytea": "Binary",
        "json": "String",
        "jsonb": "String",
        "uuid": "String",
        "xml": "String",
    }
    
    find_result = source_type.find("(")
    source_type = source_type[:find_result] if find_result != -1 else source_type
    source_type = re.sub(r"\d+", "", source_type)
    source_type = source_type.lower().strip()
    
    return type_mapping.get(source_type, "String")

def convert_polars_to_bq(polars_type: str) -> str:
    """Convert Polars dtype to BigQuery type"""
    type_mapping = {
        "Int8": "INTEGER",
        "Int16": "INTEGER",
        "Int32": "INTEGER",
        "Int64": "INTEGER",
        "UInt8": "INTEGER",
        "UInt16": "INTEGER",
        "UInt32": "INTEGER",
        "UInt64": "INTEGER",
        "Float32": "FLOAT",
        "Float64": "FLOAT",
        "String": "STRING",
        "Boolean": "BOOLEAN",
        "Date": "DATE",
        "Datetime": "TIMESTAMP",
        "Binary": "BYTES",
    }
    
    return type_mapping.get(polars_type, "STRING")

def get_hours_ago(hours_ago: int) -> str:
    lookback = datetime.now(timezone.utc) - timedelta(hours=hours_ago)
    return lookback.strftime("%Y-%m-%d %H:%M:%S")