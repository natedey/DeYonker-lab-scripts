#!/home/dwappett/miniconda3/envs/pymol/bin/python3
"""
Created by DAW 2025-07-01
Script for getting RMSDs of each FG
"""

import sys, os
import argparse
import pandas as pd
#import pymol
from pymol import cmd
from read_write_pdb import *
from model_details import *
from check_residue_atom import *

def FG_RMSD(pdbf1,pdbf2,sel_key):
    # load pdbs for pymol processing
    cmd.load(pdbf1, "pdb1")
    cmd.load(pdbf2, "pdb2")

    # find FGs mutual to both strucs
    lst1 = get_model_FGs(pdbf1,sel_key)
    lst2 = get_model_FGs(pdbf2,sel_key)
    FGs = [f for f in lst1 if f in lst2]
    
    # get RMSD using pymol rms_cur function (doesn't align first)
    frms = {}
    for f in FGs:
        fid = f[0].split(':')
        if f[1].startswith('SC'):
            if f[1].endswith('GLY'):
                continue
            else: 
                sel = f'chain {fid[0]} and resi {fid[1]} and sidechain and not (elem H and bound_to name CA)'
        elif f[1] == 'MC':
            sel = f'((chain {fid[0]} and resi {fid[1]} and (name C or name O)) or (chain {fid[0]} and resi {int(fid[1])+1} and (name N or name H)))'
        else:
            sel = f'chain {fid[0]} and resi {fid[1]}'
        #frms[f[0]+':'+f[1]] = cmd.rms_cur(f'(pdb1 and {sel})',f'(pdb2 and {sel})')
        val = cmd.rms_cur(f'(pdb1 and {sel})',f'(pdb2 and {sel})')
        atct = cmd.count_atoms(f'(pdb1 and {sel})')
        frms[f[0]+':'+f[1]] = {'rmsd': val, 'N_at': atct, 'av_per_at': val/atct}

    # create df, sort, get means, round
    df = pd.DataFrame.from_dict(frms,orient='index')
    midx = [('seed',f) if (f.split(':')[0],int(f.split(':')[1])) in sel_key else ('SC',f) if 'SC_' in f else ('MC',f) if 'MC' in f else ('WAT',f) if ('WAT' in f or 'HOH' in f) else ('other', f) for f in frms.keys()]
    df.index = pd.MultiIndex.from_tuples(midx)
    df2 = df['rmsd'].groupby(level=0,sort=False).agg(['mean','count'])
    df2.loc['all'] = [df['rmsd'].mean(),df['rmsd'].count()]
    df = df.round(2)
    df2 = df2.round(2)
    return df, df2


def compare_two(sel_key,pdbf1,pdbf2):
    df, df2 = FG_RMSD(pdbf1,pdbf2,sel_key)
    print('mean RMSDs by category')
    print(df2)
    print('\ngroups with RMSD > 0.5 or av. RMSD per atom > 0.1')
    print(df.loc[(df['av_per_at']>0.1)|(df['rmsd']>0.5)])
    return df, df2


def compare_list_to_one(sel_key,pdbf1,modlist):
    for m in modlist:
        #mnum = m.split('/')[0].replace('model_','')
        fname = m.split('/')[-1].replace('.pdb','').split('_')
        fname = [f for f in fname if f not in ['xtal','opt','xtb','prod','react','ts'] and not f.startswith('MD')]
        mnum = fname[0]
        newdf, newdf2 = FG_RMSD(pdbf1,m,sel_key)
        if modlist.index(m) == 0:
            #df = newdf.drop(columns=['N_at','av_per_at'])
            df = newdf.drop(columns=['N_at','rmsd'])
            df.columns = [mnum]
        else:
            #newdf = newdf.drop(columns=['N_at','av_per_at'])
            newdf = newdf.drop(columns=['N_at','rmsd'])
            newdf.columns = [mnum]
            df = df.merge(newdf,how='outer',left_index=True, right_index=True)
    df = df.reset_index(level=0,drop=True)
    df['max'] = df.max(axis=1)
    #filt = df.loc[df['max']>1]
    filt = df.loc[df['max']>0.1]
    filt = filt.drop(columns='max')
    collist = list(filt.columns.values)
    collist.reverse()
    for c in collist:
        filt.sort_values(by=c, inplace=True, ascending=False)
    print(filt)
    return df, filt


def group_and_compare(sel_key,modlist,comp):
    # sort modlist:
    filedict = {}
    for m in modlist:
        fname = m.replace('.pdb','').split('_')
        fname = [f for f in fname[1:] if f not in ['xtb','opt']]
        if fname[0] not in filedict.keys():
            filedict[fname[0]] = {}
        filedict[fname[0]][fname[-1]] = m
    # define pairs: all strucs of model, and between adjacent models
    pairs = {}
    if comp == 'inmod':
        for m in filedict.keys():
            if 'ts' in filedict[m].keys() and 'template' in filedict[m].keys():
                pairs[f'{m}_ts_tmp'] = (filedict[m]['ts'],filedict[m]['template'])
            if 'react' in filedict[m].keys() and 'ts' in filedict[m].keys():
                pairs[f'{m}_ts_r'] = (filedict[m]['ts'],filedict[m]['react'])
            if 'prod' in filedict[m].keys() and 'ts' in filedict[m].keys():
                pairs[f'{m}_ts_p'] = (filedict[m]['ts'],filedict[m]['prod'])
            if 'react' in filedict[m].keys() and 'prod' in filedict[m].keys():
                pairs[f'{m}_r_p'] = (filedict[m]['react'],filedict[m]['prod'])
    elif comp == 'adjmod':
        sortedmods = list(filedict.keys())
        sortedmods.sort()
        for m in sortedmods[0:-1]:
            idx = sortedmods.index(m)
            mnext = sortedmods[idx+1]
            for i in [('ts','ts'),('prod','p'),('react','r')]:
                if i[0] in filedict[m].keys() and i[0] in filedict[mnext].keys():
                    pairs[f'{m}_{mnext}_{i[1]}'] = (filedict[m][i[0]], filedict[mnext][i[0]])
    for m in pairs.keys():
        newdf, newdf2 = FG_RMSD(pairs[m][0],pairs[m][1],sel_key)
        if list(pairs.keys()).index(m) == 0:
            df = newdf.drop(columns=['N_at','av_per_at'])
            df.columns = [m]
        else:
            newdf = newdf.drop(columns=['N_at','av_per_at'])
            newdf.columns = [m]
            df = df.merge(newdf,how='outer',left_index=True, right_index=True)
    df = df.reset_index(level=0,drop=True)
    df['max'] = df.max(axis=1)
    filt = df.loc[df['max']>0.5]
    filt = filt.drop(columns='max')
    collist = list(filt.columns.values)
    collist.reverse()
    for c in collist:
        filt.sort_values(by=c, inplace=True, ascending=False)
    print(filt.T)
    return df, filt, pairs

### script for getting RMSDs of each functional group ###
if __name__ == '__main__':
    """
    Ways to use:
    -pdb1 [*.pdb] -pdb2 [*.pdb]     => simple between two strucs
    -pdb1 [*.pdb] -list [*.txt]     => between one main pdb and all pdbs in list file (list has one pdb file per line)
    -list [*.txt]                   => picks pairs of strucs to compare for you
    WARNING! Assumes pdb files roughly follow my naming convention: system_model[_method]_struc_opt.pdb e.g. MD1341_41_xtb_ts_opt.pdb, xtal_12_react_opt.pdb, etc (also works with model_N_template.pdb)
    """
    parser = argparse.ArgumentParser(description='Get RMSDs of each functional group')
    parser.add_argument('-s','-seed', dest='seed', default=None, help='Chain:Resid,Chain:Resid')
    parser.add_argument('-pdb1', dest='pdb1', default=None, help='First PDB for comparison')
    parser.add_argument('-pdb2', dest='pdb2', default=None, help='Second PDB for comparison')
    parser.add_argument('-list', dest='list', default=None, help='txt file listing pdbs to compare')
    parser.add_argument('-comp', dest='comp', default='inmod', help='[inmod/adjmod] type of comparison to do(with list only)')
    args = parser.parse_args()

    pd.set_option('display.max_rows', 500)
    sel_key = get_sel_keys(args.seed)
    if args.list:
        modlist = open(args.list).readlines()
        modlist = [l.strip() for l in modlist]

    if args.pdb1 and args.pdb2 and not args.list:
        df, df2 = compare_two(sel_key,args.pdb1,args.pdb2)
    elif args.pdb1 and args.list and not args.pdb2:
        df, filt = compare_list_to_one(sel_key,args.pdb1,modlist)
    elif args.list and not args.pdb1 and not args.pdb2:
        df, filt, pairs = group_and_compare(sel_key,modlist,args.comp)
    else:
        print('I don\'t know what I\'m meant to be comparing')
        sys.exit()

