#!/bin/sh

# Script for making sure excluded strucs don't have fixable Hdetached/bond breaking issues! 
# Created DAW 2026-Nov
# User MUST have a pymol conda environment with the conda pymol package so the API can be used!!!!!

### starting bash code determines that this script should use the python executable from the pymol conda environment ###
if "true" : '''\'
then
exec "$HOME/miniconda3/envs/pymol/bin/python3" "$0" "$@"
exit 127
fi
'''
### then the script continues as a normal python script ###
### idea found here: https://unix.stackexchange.com/questions/20880/how-can-i-use-environment-variables-in-my-shebang ###


import os, os.path
import glob
import argparse
import time
import subprocess
from subprocess import Popen, PIPE,STDOUT
from pymol import cmd
from read_write_pdb import read_pdb
from model_details import get_model_FGs
from probe2rins import atom_split
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt

def check_excluded_Hdetached(structype,framedirs,hasHdetached,warnings):
    parentdir = os.getcwd()
    for f in framedirs:
        os.chdir(f)
        # get path of template pdb: one level above tsopt/2 above ircs
        if structype == "tsopt":
            templatepdb = glob.glob(f'../model_*_template.pdb')[0]
        else:
            templatepdb = glob.glob(f'../../model_*_template.pdb')[0]

        # make sure there's an orca.xyz file to check!
        if not os.path.isfile('orca.xyz'):
            warnings.append(f'{parentdir}/{f} has no orca.xyz file!')
        else:
            # convert excluded geom to pdb because Hdetached check needs residue info
            out = subprocess.run([f'xyz_to_pdb.py -pdb {templatepdb} -name excluded.pdb'],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)

            # get heavy/hydrogen atom lists
            pdb, res_info, tot_charge = read_pdb(f'excluded.pdb')
            allH = [f'{line[5]}/{line[6]}/{line[2].strip()}' for line in pdb if line[2].strip().startswith('H')]
            allheavy = [f'{line[5]}/{line[6]}/{line[2].strip()}' for line in pdb if not line[2].strip().startswith('H')]

            # load pdb and excluded strucs as pymol objects
            cmd.load(templatepdb,'tmp')
            cmd.load('excluded.pdb','excl')

            # find what each H in template pdb is covalently bound to (= closest heavy atom with same residue id)
            H_bound_tmp = {}
            for i in allH:
                res_heavy = [j for j in allheavy if i.rsplit('/',1)[0] in j]
                heavydists_tmp = {j: cmd.get_distance(f'tmp//{i}',f'tmp//{j}') for j in res_heavy}
                H_bound_tmp[(i,min(heavydists_tmp,key=heavydists_tmp.get))] = heavydists_tmp[min(heavydists_tmp,key=heavydists_tmp.get)]

            # check if any of the pairs that should be bound have distance > 1.1 * original dist (just allowing for slight variations between amberff and xtb)
            # when an unbound pair is found, log the struc and move to the next one (don't need to waste time checking rest of pairs)
            for pair in H_bound_tmp.keys():
                if cmd.get_distance(f'excl//{pair[0]}',f'excl//{pair[1]}') > (H_bound_tmp[pair] * 1.1):
                    hasHdetached.append(f'{parentdir}/{f}')
                    break 
                         
            # delete all pymol objects for this model so nothing left to potentially interfere with next iteration
            for obj in [n for n in cmd.get_names("all") if 'f00001' not in n]: cmd.delete(obj)

        os.chdir(parentdir)

    return hasHdetached, warnings

if __name__ == '__main__':
    st = time.perf_counter()
    
    parser = argparse.ArgumentParser(description="run Hdetached check on excluded structures to make sure their issues aren't fixable")
    #parser.add_argument('-dir',dest='workdir',default='.',help='directory to collect results for, default = current dir')
    args = parser.parse_args()

    testing = True

    # parent QM dir
    homedir = os.getcwd()

    # set up log for models with Hdetachments and ones that couldn't be checked
    hasHdetached = []
    warnings = []

    excluded_count = 0

    # script to be run in QM dir, will loop through all dirs in to-collect.txt file
    parentdirs = [line.strip() for line in open('to-collect.txt','r').readlines()]
    for pd in parentdirs:
        os.chdir(pd)
        # check everything in any excluded list
        excluded_lists = glob.glob('check_*_excluded.txt')
        if excluded_lists:
            for el in excluded_lists:
                # split filename to get whether list is tsopt or irc
                structype = el.split('_')[1]
                # extract just dir names from file
                framedirs = [line.split()[0] for line in open(el,'r').readlines()]
                # add to count
                excluded_count += len(framedirs)
                # run check
                print(f'Rechecking {pd} excluded {structype}s = {", ".join(framedirs)}')
                hasHdetached, warnings = check_excluded_Hdetached(structype,framedirs,hasHdetached,warnings)
        os.chdir(homedir)

    # write file of results 
    with open('check_all_excluded_Hdetached.txt','w') as fp:
        fp.write(f'{excluded_count} excluded structures (tsopts and ircs) rechecked\n')
        fp.write(f'{len(hasHdetached)} excluded structures have H detachments and might be fixable\n')
        fp.write(f'{len(warnings)} structures did not have orca.xyz structures to check\n')
        
        if hasHdetached:
            fp.write('\n----- H detachments found -----\n')
            fp.write('\n'.join(hasHdetached))
            fp.write('\n')
        if warnings:
            fp.write('\n----- No orca.xyz files to check -----\n')
            fp.write('\n'.join(warnings))
    print('Results written to check_all_excluded_Hdetached.txt')
    print(f'Summary: rechecked {excluded_count} excluded models, {len(hasHdetached)} have H detachments, {len(warnings)} are missing orca.xyz files')

    et = time.perf_counter()
    seconds = et-st
    m, s = divmod(seconds, 60)
    print(f'Completed in {int(m)} minute(s) and {int(s)} second(s)')
