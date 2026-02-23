#!/usr/bin/env python3
"""
This is a script for replacing geometries in orca input files
Written by Domi Wappett 
at the University of Memphis.
2025/11/25
"""

import os, os.path
import sys, re
import argparse
import subprocess
from read_write_pdb import *
from orca_xyz_split import split_xyz_file
from numpy import *

def replace_inp_xyz(inplines,coords,geomlabel):
    coordstart = [i for i,s in enumerate(inplines) if "xyz" in s][0]
    coordend = [i for i,s in enumerate(inplines) if s.strip() == '*'][0]
    oldgeom = [l.strip().split() for l in inplines[coordstart+1:coordend]]
    newgeom = []
    for i in range(len(oldgeom)):
        newline = oldgeom[i]
        newline[0] = "%6s"%newline[0]
        for j in [1,2,3]:
            #newline[j] = "%.6f"%coords[i][j-1]
            #newline[j] = "%8.3f"%coords[i][j-1]
            newline[j] = "%.14f"%coords[i][j-1]
        if len(newline) > 4:
            newline[4] = " "+newline[4]
        newline = " ".join(newline)+"\n"
        #newline = "  " + " ".join(newline)+"\n"
        newgeom.append(newline)
    if geomlabel:
        if not geomlabel.endswith('\n'):
            geomlabel = geomlabel+'\n'
        newinp = inplines[0:coordstart] + [geomlabel] + [inplines[coordstart]] + newgeom + inplines[coordend:]
    else:
        newinp = inplines[0:coordstart+1] + newgeom + inplines[coordend:]
    return newinp

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Replace geometry in orca input file')
    parser.add_argument('-inp', default='orca.inp', help='input_name, default orca.inp')
    parser.add_argument('-xyz', default='orca.xyz', help='output_structure, default orca.xyz')
    parser.add_argument('-xyzframe', default=None, help='frame to read from xyz file with multiple strucs')
    parser.add_argument('-tsopt', action='store_true', help='prepare full ts opt')
    parser.add_argument('-inhess', dest='inhess', default='orca.hess', help='inhess to read')

    args = parser.parse_args()
   
    # get new coords from xyz file 
    if args.xyzframe:
        strucs = split_xyz_file(args.xyz,args.xyzframe)
        xyz = strucs[int(args.xyzframe)]
        label = f"# geom from frame {args.xyzframe} of {args.xyz}"
    else:
        xyz = open(args.xyz).readlines()
        label = f"# geom from {args.xyz}"
    xyz = [c.strip().split() for c in xyz[2:]]
    coords = array(xyz)[:,1:].astype(float)


    # get input file contents
    inplines = open(args.inp).readlines()
    # remove comment lines. if you want "permanent" comments start them with 2 or more hashes like: "### this comment won't be deleted"
    inplines = [l for l in inplines if not l.startswith('# ')]
  
    # if tsopt option selected, make changes to input file contents 
    if args.tsopt:
        if ' opt ' not in inplines[0]:
            inplines[0] = inplines[0].replace('! ','! optts ')
        else:
            inplines[0] = inplines[0].replace(' opt ',' optts ')
        inplines = [l for l in inplines if "{ B" not in l]
        geomstart = [i for i,s in enumerate(inplines) if '%geom' in s][0]
        inplines = inplines[0:geomstart+1] + ['  inhess read\n',f'  inhessname "{args.inhess}"\n'] + inplines[geomstart+1:] 
    
    #label = f"# geom from {args.xyz}"

    # do coord replacement stuff
    newinp = replace_inp_xyz(inplines,coords,label)

    # write the new input contents into orca.inp
    # (overwrites existing orca.inp. make sure you use propagate_orca first!)
    with open('orca.inp','w') as f:
        for l in newinp:
            f.write(l)
