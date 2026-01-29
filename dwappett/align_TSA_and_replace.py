#!/usr/bin/env python3
"""
Script created by DAW late 2024/early 2025
"""
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
    newcoord = {atom[2].strip(): {'x': atom[8], 'y': atom[9], 'z': atom[10]} for atom in new_pdb}
    #temporary_pdb = []
    #tsadone = 0
    for line in mod_pdb:
        if line[4].strip() == lig:
            #atomname=line[2],x=line[8],y=line[9],z=line[10]
            line[8] = newcoord[line[2].strip()]['x']
            line[9] = newcoord[line[2].strip()]['y']
            line[10] = newcoord[line[2].strip()]['z']
        #if line[4].strip() == lig and tsadone == 0:
        #    temporary_pdb += new_pdb
        #    #temporary_pdb.append(new_pdb)
        #    tsadone = 1
        #elif line[4].strip() != lig:
        #    temporary_pdb.append(line)
 
    #write_pdb('tsguess.pdb',temporary_pdb)
    write_pdb('tsguess.pdb',mod_pdb)   

##########
# align optimized ts with ligand in optimized model
# used to replace whole ligand with aligned ts geom by ID instead of atom list (commented out code above)
# but as of jan 2026 it's by coords to make sure that original ligand name and ch/id are preserved, not using ones from old ts
##########
if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Create tsguess.pdb for chorismate mutase models. Aligns old TS geom to model PDB ligand and then replaces it.")
    parser.add_argument("-modpdb")
    parser.add_argument("-tspdb",default='/project/dwappett/chorismate_mutase/opts-expanded-models/res_13-ts-new-02-out.pdb')
    parser.add_argument("-newpdb",default='old_TS_aligned.pdb')
    parser.add_argument("-md",action='store_true')
    args = parser.parse_args()
    modelpdb = args.modpdb
    tspdb = args.tspdb
    newpdb = args.newpdb
    md = args.md
    
    if md:
        lig = 'COR'
    else:
        lig = 'TSA'
    
    # align old ts to model
    with open("log.pml", "w") as logf:
        logf.write(f"load {modelpdb}, modelpdb\n")
        logf.write(f"load {tspdb}, tspdb\n")
        #if md:
        #    logf.write(f"pair_fit (tspdb and resn TSA and elem O), (modelpdb and resn COR and elem O)\n")
        #else:
        #    logf.write(f"pair_fit (tspdb and resn TSA and elem O), (modelpdb and resn TSA and elem O)\n")
        logf.write(f"pair_fit (tspdb and resn TSA and elem O), (modelpdb and resn {lig} and elem O)\n")
        logf.write(f'save {newpdb}, (tspdb and resn TSA)\n')
        logf.write(f"list1 = []\niterate (tspdb and resn TSA), list1.append((chain,resi,resn,name))\nlist2 = []\niterate (modelpdb and not resn COR and not resn TSA), list2.append((chain,resi,resn,name))\n")
        logf.write("""python
clashes = []
for at1 in list1:
    for at2 in list2:
        sel1 = f"tspdb//{at1[0]}/{at1[1]}/{at1[3]}"
        sel2 = f"modelpdb//{at2[0]}/{at2[1]}/{at2[3]}"
        d = cmd.get_distance(atom1=sel1,atom2=sel2)
        if d <= 1:
            d = "%0.2f"%d
            clashes.append(f'Atoms {at1[0]}/{at1[1]}/{at1[2]}/{at1[3]} and {at2[0]}/{at2[1]}/{at2[2]}/{at2[3]} are only {d} apart!')
if clashes:
    with open('tsguess_close_atoms.txt','w+') as f:
        f.write('\\n'.join(clashes))
python end""")
#print(f'Atoms {at1[0]}/{at1[1]}/{at1[2]}/{at1[3]} and {at2[0]}/{at2[1]}/{at2[2]}/{at2[3]} are only {d} apart!')

    cmd = "pymol -qc log.pml"
    system_run(cmd)
    
    
    makeguesspdb(modelpdb,newpdb,lig)
    
