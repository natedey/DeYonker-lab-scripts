#!/usr/bin/env python
"""
DAW prototype (F)I-SAPT input generation script
created early 2025
"""

import sys, os, argparse
from read_write_pdb import *
from pathlib import Path


def fisapt_input(inp_name,inp_temp,charge,multiplicity,pdb,tot_charge,seed):
    ### From input_template file ###
    ### memory
    ### set_num_threads
    ### molecule
    ### set_globals
    ### set_sapt
    ### energy

    with open(inp_temp) as f:
        lines = f.readlines()
    for line in lines:
        if line.startswith('#'): continue
        if line.startswith('memory'):
            memory = line.split(':')[1].strip()
        if line.startswith('set_num_threads'):
            threads = line.split(':')[1].strip()
        if line.startswith('molecule'):
            mol = line.split(':')[1].split(',')
        if line.startswith('set_globals'):
            setglob = line.split(':')[1].split(',')
        if line.startswith('energy'):
            energy = line.split(':')[1].strip()

    ## write input
    inp = open('%s'%inp_name,'w')
    # write starting stuff
    inp.write("memory %s\n\n"%memory)
    inp.write("set_num_threads(%s)\n\n"%threads)
    inp.write("molecule mol {\n")
    # overall charge and multiplicity
    inp.write("%s %s\n--\n"%(charge+tot_charge,multiplicity))
    # fragment A
    inp.write("CHRG MULT\n")
    for i in fragdict.keys():
        if fragdict[i]['frag']=='A':
            inp.write("%1s %8.3f %8.3f %8.3f\n"%(fragdict[i]['elem'],fragdict[i]['x'],fragdict[i]['y'],fragdict[i]['z']))
    inp.write("--\n")
    # fragment B
    inp.write("CHRG MULT\n")
    for i in fragdict.keys():
        if fragdict[i]['frag']=='B':
            inp.write("%1s %8.3f %8.3f %8.3f\n"%(fragdict[i]['elem'],fragdict[i]['x'],fragdict[i]['y'],fragdict[i]['z']))
    inp.write("--\n")
    # fragment C
    inp.write("CHRG MULT\n")
    for i in fragdict.keys():
        if fragdict[i]['frag']=='X':
            inp.write("%1s %8.3f %8.3f %8.3f\n"%(fragdict[i]['elem'],fragdict[i]['x'],fragdict[i]['y'],fragdict[i]['z']))
    # rest of inp stuff
    for m in mol:
        inp.write("\t%s\n"%m)
    inp.write("} \n \n")
    inp.write("set globals {\n")
    for g in setglob:
        inp.write("\t%s\n"%g)
    inp.write("} \n \n")
    inp.write("set sapt print 1\n\n")
    inp.write("energy('%s')\n"%energy)

    inp.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='FISAPT setup')
    parser.add_argument('-pdb', dest='pdbf', default=None, help='model pdb')
    parser.add_argument('-part', dest='seedpart', default=None, help='file specifying atoms in frags A and X (everything else automatically assigned to B). each line should list: chain id atom frag')
    parser.add_argument('-c', dest='charge', default=0, help='seed charge')
    parser.add_argument('-m', dest='multi', default=1, help='multiplicity')

    args = parser.parse_args()
    pdbf = args.pdbf
    seedpart = args.seedpart
    charge = int(args.charge)

    tmpltdir = Path.home() / 'git' / 'RINRUS' / 'template_files'
    int_tmp = tmpltdir / 'psi4-fsapt_input_template.txt'

    ### read pdb ###
    pdb, res_info, tot_charge = read_pdb(pdbf)
    fragdict = {}
    for atom in pdb:
        key = (atom[5],atom[6],atom[2].strip())
        # all as B until otherwise stated
        fragdict[key] = {'frag': 'B', 'x': atom[8], 'y': atom[9], 'z': atom[10], 'elem': atom[14].strip()}

    ### id parts ###
    splist = open(seedpart,'r').readlines()
    for line in splist:
        line = line.split()
        key = (line[0],int(line[1]),line[2])
        fragdict[key]['frag'] = line[3]

    ### write input file ###
    fisapt_input('input.dat',int_tmp,charge,args.multi,pdb,tot_charge,fragdict)
