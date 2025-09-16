#!/usr/bin/env python
"""
DAW script for formatting PDB files for ORCA QM/MM calcs
"""

import sys, os, argparse
from read_write_pdb import *

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='add qm atom flags to protein pdb based on rinrus res_n.pdb for orca qm/mm')
    parser.add_argument('-pdb', dest='pdbf', default=None, help='whole protein pdb')
    parser.add_argument('-resn', dest='qmpdb', default=None, help='rinrus res_n.pdb structure (uncapped model)')

    args = parser.parse_args()

    pdb, res_info, tot_charge = read_pdb(args.pdbf)
    qmpdb, qm_resinfo, qm_tot_charge = read_pdb(args.qmpdb)
    
    qmatoms = []
    # list of (ch,id,atom) tuples in res_N.pdb
    for atom in qmpdb:
         qmatoms.append((atom[5],atom[6],atom[2].strip()))

    truncHA = []
    for atom in qmatoms:
        if atom[2] == 'HA':
            if not ((atom[0],atom[1],'C') in qmatoms and (atom[0],atom[1],'N') in qmatoms):
                truncHA.append(atom)

    qmatoms = [atom for atom in qmatoms if atom not in truncHA]

    # go through whole protein pdb, check if atom in qm atom list, set occ column to match
    newpdb = []
    for atom in pdb:
        if (atom[5],atom[6],atom[2].strip()) in qmatoms:
            atom[11] = 1
        else:
            atom[11] = 0
        newpdb.append(atom)

    pdbout = args.pdbf.replace('.pdb','.qmmm.pdb')
        
    write_pdb(pdbout,newpdb)

