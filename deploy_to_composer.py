#!/usr/bin/env python3
"""
Deploy DAGs and plugins to Composer bucket via Cloud Build.
Based on gcp-healthcare-project pattern.
"""

import argparse
import glob
import os
import tempfile
from shutil import copytree, ignore_patterns
from google.cloud import storage


def _create_file_list(directory: str, name_replacement: str) -> tuple[str, list[str]]:
    """Copies relevant files to a temporary directory and returns the list."""
    if not os.path.exists(directory):
        print(f"⚠️ Warning: Directory '{directory}' does not exist. Skipping upload.")
        return "", []

    temp_dir = tempfile.mkdtemp()
    files_to_ignore = ignore_patterns("*_test.py", "*.pyc", "__pycache__")
    copytree(directory, f"{temp_dir}/", ignore=files_to_ignore, dirs_exist_ok=True)
    
    # Ensure only files are returned
    files = [f for f in glob.glob(f"{temp_dir}/**", recursive=True) if os.path.isfile(f)]
    return temp_dir, files


def upload_to_composer(directory: str, bucket_name: str, name_replacement: str) -> None:
    """Uploads DAGs or plugins to Composer's Cloud Storage bucket."""
    temp_dir, files = _create_file_list(directory, name_replacement)

    if not files:
        print(f"⚠️ No files found in '{directory}'. Skipping upload.")
        return

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)

    for file in files:
        file_gcs_path = file.replace(f"{temp_dir}/", name_replacement)
        try:
            blob = bucket.blob(file_gcs_path)
            blob.upload_from_filename(file)
            print(f"✅ Uploaded {file} to gs://{bucket_name}/{file_gcs_path}")
        except IsADirectoryError:
            print(f"⚠️ Skipping directory: {file}")
        except FileNotFoundError:
            print(f"❌ Error: {file} not found. Ensure directory structure is correct.")
            raise


if __name__ == "__main__":
    try:
        parser = argparse.ArgumentParser(description="Upload DAGs and plugins to Composer bucket.")
        parser.add_argument("--dags_directory", help="Path to DAGs directory.")
        parser.add_argument("--plugins_directory", help="Path to plugins directory.")
        parser.add_argument("--composer_bucket", help="GCS bucket name for Composer.")

        args = parser.parse_args()

        print(f"📁 DAGs directory: {args.dags_directory}")
        print(f"🔌 Plugins directory: {args.plugins_directory}")
        print(f"🪣 Composer bucket: {args.composer_bucket}")

        if args.dags_directory and os.path.exists(args.dags_directory):
            print("🚀 Starting DAGs upload...")
            upload_to_composer(args.dags_directory, args.composer_bucket, "dags/")
            print("✅ DAGs upload completed!")
        else:
            print(f"⚠️ Skipping DAGs upload: '{args.dags_directory}' directory not found.")

        if args.plugins_directory and os.path.exists(args.plugins_directory):
            print("🚀 Starting plugins upload...")
            upload_to_composer(args.plugins_directory, args.composer_bucket, "plugins/")
            print("✅ Plugins upload completed!")
        else:
            print(f"⚠️ Skipping plugins upload: '{args.plugins_directory}' directory not found.")

        print("🎉 Deployment completed!")
    except Exception as e:
        print(f"❌ Error during deployment: {str(e)}")
        import traceback
        traceback.print_exc()
        exit(1)