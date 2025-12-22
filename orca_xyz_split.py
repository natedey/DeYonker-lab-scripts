#!/usr/bin/env python3

import argparse

def split_xyz_file(input_file):
    """
    Splits an XYZ file with multiple geometries into separate XYZ files.
    
    Args:
        input_file (str): Path to the input XYZ file.
    """
    try:
        with open(input_file, 'r') as file:
            lines = file.readlines()
        
        geometry = []
        geometry_count = 1
        
        for line in lines:
            if line.strip().isdigit():
                # If we encounter a digit, it indicates a new geometry
                if geometry:
                    # Save the current geometry to a file
                    output_file = f"geometry_{str(geometry_count).zfill(3)}.xyz"
                    with open(output_file, 'w') as out_file:
                        out_file.writelines(geometry)
                    print(f"Written: {output_file}")
                    geometry_count += 1
                    geometry = []  # Reset for the next geometry
            geometry.append(line)
        
        # Save the last geometry
        if geometry:
            output_file = f"geometry_{geometry_count}.xyz"
            with open(output_file, 'w') as out_file:
                out_file.writelines(geometry)
            print(f"Written: {output_file}")

    except FileNotFoundError:
        print(f"Error: File '{input_file}' not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

def main():
    parser = argparse.ArgumentParser(description="Split an XYZ file with multiple geometries into separate files.")
    parser.add_argument("input_file", type=str, help="Path to the input XYZ file")
    
    args = parser.parse_args()
    split_xyz_file(args.input_file)

if __name__ == "__main__":
    main()

