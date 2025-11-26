#!/usr/bin/env python3
"""
Convert CSV files with Python byte string literals to PostgreSQL hex format for BYTEA columns.
This script processes CSV files and converts byte string literals (b'...') to hex format (\\x...).
"""

import csv
import sys
import re
import os
from pathlib import Path

def convert_byte_string_to_hex(byte_str):
    r"""
    Convert Python byte string literal to PostgreSQL hex format.
    
    Example:
        Input:  "b'GIF89aP\x001\x00...'"
        Output: "\x47494638396150003100..."
    """
    if not byte_str or not isinstance(byte_str, str):
        return byte_str
    
    # Check if it's a Python byte string literal
    if not byte_str.startswith("b'") and not byte_str.startswith('b"'):
        return byte_str
    
    try:
        # Remove b'...' wrapper and decode escape sequences
        # Handle both b'...' and b"..."
        if byte_str.startswith("b'"):
            inner = byte_str[2:-1]  # Remove b' and trailing '
        else:
            inner = byte_str[2:-1]  # Remove b" and trailing "
        
        # Decode escape sequences like \x00, \n, etc.
        # Use eval to safely decode the byte string (it's already in the CSV, so safe)
        try:
            decoded_bytes = eval(f"b'{inner}'")
        except:
            # Fallback: try with double quotes
            try:
                decoded_bytes = eval(f'b"{inner}"')
            except:
                # If eval fails, return as-is
                return byte_str
        
        # Convert to hex format for PostgreSQL
        hex_str = r'\x' + decoded_bytes.hex()
        return hex_str
    except Exception as e:
        print(f"Warning: Could not convert byte string: {e}", file=sys.stderr)
        return byte_str

def process_csv_file(input_file, output_file):
    """Process a CSV file and convert byte string literals to hex format."""
    # Increase CSV field size limit to handle large BYTEA fields
    csv.field_size_limit(sys.maxsize)
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8', newline='') as outfile:
        
        reader = csv.reader(infile)
        writer = csv.writer(outfile)
        
        for row in reader:
            # Convert each field that looks like a byte string
            converted_row = []
            for field in row:
                if field and (field.startswith("b'") or field.startswith('b"')):
                    converted_row.append(convert_byte_string_to_hex(field))
                else:
                    converted_row.append(field)
            writer.writerow(converted_row)

def main():
    """Main function to process CSV files."""
    if len(sys.argv) < 2:
        print("Usage: convert_bytea_csv.py <input_file> [output_file]")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else input_file + '.converted'
    
    if not os.path.exists(input_file):
        print(f"Error: File not found: {input_file}", file=sys.stderr)
        sys.exit(1)
    
    try:
        process_csv_file(input_file, output_file)
        # Replace original with converted if output_file is same as input
        if len(sys.argv) == 2:
            os.replace(output_file, input_file)
        print(f"Converted: {input_file} -> {output_file}")
    except Exception as e:
        print(f"Error processing {input_file}: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()

