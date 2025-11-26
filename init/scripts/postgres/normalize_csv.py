#!/usr/bin/env python3
"""
Normalize CSV files: Convert float values to integers for integer columns.
This script processes CSV files and converts float values (e.g., "14.0") to integers (e.g., "14").
"""

import csv
import sys
import os

def normalize_integer_field(value):
    """Convert float string to integer string if applicable."""
    if not value or value == '':
        return value
    
    try:
        # Try to parse as float first
        float_val = float(value)
        # If it's a whole number, convert to int
        if float_val.is_integer():
            return str(int(float_val))
        else:
            # If it has decimal part, keep as is (shouldn't happen for integer columns)
            return value
    except (ValueError, TypeError):
        # If not a number, return as-is
        return value

def process_csv_file(input_file, output_file, integer_columns):
    """Process a CSV file and normalize integer columns."""
    # Increase CSV field size limit
    csv.field_size_limit(sys.maxsize)
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8', newline='') as outfile:
        
        reader = csv.reader(infile)
        writer = csv.writer(outfile)
        
        # Read header
        header = next(reader)
        writer.writerow(header)
        
        # Find indices of integer columns
        integer_indices = []
        for col_name in integer_columns:
            try:
                idx = header.index(col_name)
                integer_indices.append(idx)
            except ValueError:
                pass  # Column not found, skip
        
        # Process each row
        for row in reader:
            normalized_row = []
            for idx, field in enumerate(row):
                if idx in integer_indices:
                    normalized_row.append(normalize_integer_field(field))
                else:
                    normalized_row.append(field)
            writer.writerow(normalized_row)

def main():
    """Main function to process CSV files."""
    if len(sys.argv) < 3:
        print("Usage: normalize_csv.py <input_file> <output_file> <column1> [column2] ...")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    integer_columns = sys.argv[3:] if len(sys.argv) > 3 else []
    
    if not os.path.exists(input_file):
        print(f"Error: File not found: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    try:
        process_csv_file(input_file, output_file, integer_columns)
        print(f"Normalized: {input_file} -> {output_file}")
    except Exception as e:
        print(f"Error processing {input_file}: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

