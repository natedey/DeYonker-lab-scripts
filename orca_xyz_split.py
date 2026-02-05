#!/usr/bin/env python3

import argparse

def split_xyz_file(input_file,frame):
    lines = open(input_file, 'r').readlines()    
    struclen = lines[0].strip()
    strucs = {}
    count = 1
    lengths = {}
    currentgeom = []
    for i, line in enumerate(lines):
        if i>0 and line.strip().isdigit() and line.strip() == struclen:
            strucs[count] = currentgeom
            lengths[count] = len(currentgeom)
            count += 1
            currentgeom = []
        currentgeom.append(line)
    strucs[count] = currentgeom

    # check that all are expected length
    for f in lengths.keys():
        if lengths[f] != int(struclen)+2:
            print(f'Error: structure {f} is {lengths[f]} lines long but should be {int(struclen)+2} lines long!')
            exit()
   
    if input_file.split('/')[-1] == "orca.xyz":
        fn = "orcaxyz"
    elif input_file.split('/')[-1] == "orca_trj.xyz":
        fn = "orcatrj"
    else:
        fn = input_file.split('/')[-1].replace('.xyz','')
 
    if frame == 'all':
        for f in strucs.keys():
            output_file = f"{fn}_{str(f).zfill(3)}.xyz"
            with open(output_file, 'w') as out_file:
                    out_file.writelines(strucs[f])
    else:
        frame = int(frame)
        output_file = f"{fn}_{str(frame).zfill(3)}.xyz"
        with open(output_file, 'w') as out_file:
            out_file.writelines(strucs[frame])

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Split an XYZ file with multiple geometries into separate files or extract specific geometry.")
    parser.add_argument("input_file", help="Path to the input XYZ file")
    parser.add_argument("-frame", default='all', help="Structure to extract (integer or 'all', default 'all')")
    args = parser.parse_args()

    split_xyz_file(args.input_file,args.frame)

