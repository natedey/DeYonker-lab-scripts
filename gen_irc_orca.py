#!/usr/bin/env python3
"""
This is a modified version of Qianyi Cheng's 
gen_irc.py for orca calcs
Written by Domi Wappett 
at the University of Memphis.
2025/11/25
"""

import os, os.path
import sys, re
import argparse
import subprocess
from read_write_pdb import *
from replace_orca_inp_geom import replace_inp_xyz
from numpy import *

def write_irc_inputs(inp_f,dir1,dir2,irc1,irc2,scale):
    with open(inp_f) as f:
        inplines = f.readlines()
    inplines[0] = inplines[0].replace('optts','opt').replace('moread','').replace('tightopt','')
    inplines = [l for l in inplines if 'inhess' not in l.lower() and not l.startswith('# ') and 'calc_hess' not in l.lower()]
    # remove modify internal stuff
    if [l for l in inplines if 'modify_internal' in l]:
        mi_start = [i for i,s in enumerate(inplines) if 'modify_internal' in s][0]
        mi_end = [i for i,s in enumerate(inplines) if 'end' in s and i > mi_start][0]
        inplines = inplines[0:mi_start]+inplines[mi_end+1:]
    label1 = "# the positive pertubation structure with scale +%.2f\n"%scale
    label2 = "# the negative pertubation structure with scale -%.2f\n"%scale
    newinp1 = replace_inp_xyz(inplines,irc1,label1)
    newinp2 = replace_inp_xyz(inplines,irc2,label2)

    f1 = open('%s/orca.inp'%dir1,'w')
    f2 = open('%s/orca.inp'%dir2,'w')
    for l in range(len(newinp1)):
        f1.write(newinp1[l])
        f2.write(newinp2[l])
    f1.close()
    f2.close()


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Write irc inputs')
    parser.add_argument('-wdir', dest='output_dir', default=os.path.abspath('./'), help='working dir, default "current dir"')
    parser.add_argument('-dir1', dest='dir1', default=os.path.abspath('./irc1'), help='irc1 dir, default irc1')
    parser.add_argument('-dir2', dest='dir2', default=os.path.abspath('./irc2'), help='irc2 dir, default irc2')
    parser.add_argument('-i', dest='orca_inp', default=None, help='input_name, default orca.inp')
    parser.add_argument('-xyz', dest='orca_xyz', default=None, help='output_structure, default orca.xyz')
    parser.add_argument('-v', dest='orca_vib', default=None, help='orca_vib_xyz, default orca.hess.v006.xyz')
    parser.add_argument('-s', dest='scale', type=float,default=0.1, help='scale_factor, default 0.1')
    parser.add_argument('-n', dest='num_freq', type=int,default=6, help='number_of_mode, default first vib mode (6)')

    args = parser.parse_args()
    wdir = args.output_dir
    scale = args.scale
    num_freq = str(args.num_freq).zfill(3)
    dir1 = args.dir1
    dir2 = args.dir2
    os.mkdir(dir1)
    os.mkdir(dir2)
    
    if args.orca_inp is None:
        inp_f = '%s/orca.inp'%wdir
    else:
        inp_f = args.orca_inp
    
    if args.orca_xyz is None:
        out_f = '%s/orca.xyz'%wdir
    else:
        out_f = args.orca_xyz
    
    if args.orca_vib is None:
        vib = f'{wdir}/orca.hess.v{num_freq}.xyz'
        if not os.path.isfile(vib):
            subprocess.run(['orca_pltvib','orca.hess',str(args.num_freq)])
    else:
        vib = args.orca_vib
    
    with open(out_f) as f:
        lines = f.readlines()
    coords = array([l.strip().split() for l in lines[2:]])
    opt = coords[:,1:].astype(float)
    #atom_name = coords[:,0]
    
    with open(vib) as f:
        freqlines = f.readlines()
    nat = int(freqlines[0].strip())
    if nat != len(coords):
        print(f'number of atoms in {out_f} is not the same as number of atoms in {vib}!')
        sys.exit()
    displacement = array([l.strip().split()[4:7] for l in freqlines[2:nat+2]]).astype(float)

    irc1 = opt+scale*displacement
    irc2 = opt-scale*displacement

    write_irc_inputs(inp_f,dir1,dir2,irc1,irc2,scale)
