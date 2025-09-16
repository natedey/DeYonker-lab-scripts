#!/usr/bin/env python3
import os, sys
import subprocess
import argparse
from read_write_pdb import *

def system_run(cmd):
    print(cmd)
    exit = os.system(cmd)
    if exit != 0:
        print("failed to run:")
        print("pymol may be set as an alias in your shell. Please run 'pymol -qc log.pml'")
        print(cmd)
        sys.exit()

def makeguesspdb(modelpdb,newpdb,lig):
    mod_pdb, res_info, tot_charge_t = read_pdb(modelpdb)
    new_pdb, binfo, tot_charge = read_pdb(newpdb)
    temporary_pdb = []
    tsadone = 0
    for line in mod_pdb:
        if line[4].strip() == lig and tsadone == 0:
            temporary_pdb += new_pdb
            #temporary_pdb.append(new_pdb)
            tsadone = 1
        elif line[4].strip() != lig:
            temporary_pdb.append(line) 
    write_pdb('tsguess.pdb',temporary_pdb)    

##########
# align optimized ts with ligand in optimized model
# replace whole ligand with aligned ts geom by ID instead of atom list
##########
if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("-modpdb")
    parser.add_argument("-tspdb",default='/project/dwappett/chorismate_mutase/opts-expanded-models/res_13-ts-new-02-out.pdb')
    parser.add_argument("-newpdb",default='old_TS_aligned.pdb')
    parser.add_argument("-md",action='store_true')
    args = parser.parse_args()
    modelpdb = args.modpdb
    tspdb = args.tspdb
    newpdb = args.newpdb
    md = args.md
    
    # align old ts to model
    with open("log.pml", "w") as logf:
        logf.write(f"load {modelpdb}, modelpdb\n")
        logf.write(f"load {tspdb}, tspdb\n")
        #logf.write(f"fit (tspdb and resn TSA), (modelpdb and resn TSA)\n")
        if md:
            logf.write(f"pair_fit (tspdb and resn TSA and elem O), (modelpdb and resn COR and elem O)\n")
        else:
            logf.write(f"pair_fit (tspdb and resn TSA and elem O), (modelpdb and resn TSA and elem O)\n")
        logf.write(f'save {newpdb}, (tspdb and resn TSA)\n')
    cmd = "pymol -qc log.pml"
    system_run(cmd)
    
    # replace ts
    #mod_pdb, res_info, tot_charge_t = read_pdb(modelpdb)
    #new_pdb, binfo, tot_charge = read_pdb(newpdb)
    
    #temporary_pdb = []
    #tsadone = 0
    if md:
        lig = 'COR'
    else:
        lig = 'TSA'
    
    makeguesspdb(modelpdb,newpdb,lig)
    
    #for line in mod_pdb:
    #    if line[4].strip() == lig and tsadone == 0:
    #        temporary_pdb += new_pdb
    #        #temporary_pdb.append(new_pdb)
    #        tsadone = 1
    #    elif line[4].strip() != lig:
    #        temporary_pdb.append(line)
    #    
    #write_pdb('tsguess.pdb',temporary_pdb)
