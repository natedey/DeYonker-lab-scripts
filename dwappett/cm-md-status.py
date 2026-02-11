#!/usr/bin/env python3
"""
print model progress table from check_cm_jobs output lists
script created DAW 2026-02-06 for CM MD->QM project
"""

import os, os.path
import re
import glob
import pandas as pd

#if you have the termcolor and tabulate packages installed in your conda env, table will be coloured
try:
    from termcolor import colored
    import tabulate
    usecol=True
except ImportError:
    usecol=False

pd.set_option('display.max_rows', 500)

folders = glob.glob('f*')
folders.sort()
checkfiles = glob.glob('check_initialopt_*.txt')+glob.glob('check_tsconstrained_*.txt')+glob.glob('check_tsopt_*.txt')+glob.glob('check_irc1_*.txt')+glob.glob('check_irc2_*.txt')
statustable = {}

for f in folders:
    statustable[f] = {'initialopt': '', 'tsconstrained': '', 'tsopt': '', 'irc1': '', 'irc2': ''}
    if os.path.isfile(f'{f}/orca.inp'):
        if os.path.isfile(f'{f}/orca.out'):
            statustable[f]['initialopt'] = 'running'
        else:
            statustable[f]['initialopt'] = 'queued'
    for j in ['tsconstrained','tsopt']:
        if os.path.isfile(f'{f}/{j}/orca.inp'):
            if os.path.isfile(f'{f}/{j}/orca.out'):
                statustable[f][j] = 'running'
            else:
                statustable[f][j] = 'queued'
    for j in ['irc1','irc2']:
        if os.path.isfile(f'{f}/tsopt/{j}/orca.inp'):
            if os.path.isfile(f'{f}/tsopt/{j}/orca.out'):
                statustable[f][j] = 'running'
            else:
                statustable[f][j] = 'queued'

for fc in checkfiles:
    job = fc.replace('.txt','').split('_')[1]
    status = fc.replace('.txt','').split('_',maxsplit=2)[2]
    lines = open(fc,'r').readlines()
    for line in lines:
        line = re.split('/| ', line.strip())[0]
        statustable[line][job] = status

#properly check pending
if os.path.isfile('check_pending.txt'):
    lines = open('check_pending.txt','r').readlines()
    for line in lines:
        f = line.split()[1]
        for i in ['initialopt','tsconstrained','tsopt','irc1','irc2']:
            if i in line:
                statustable[f][i] = 'queued'

if usecol:
    statustablecol = {}
    for key1 in statustable.keys():
        statustablecol[key1] = {}
        for key2 in statustable[key1].keys():
            if not statustable[key1][key2]:
                statustablecol[key1][key2] = ''
            elif statustable[key1][key2] == 'queued' or statustable[key1][key2] == 'running':
                statustablecol[key1][key2] = colored(statustable[key1][key2],'light_blue',None)
            elif statustable[key1][key2] == 'done':
                statustablecol[key1][key2] = 'done'
            else:
                statustablecol[key1][key2] = colored(statustable[key1][key2],'red',None)
        if statustablecol[key1]['initialopt'] == 'done' and statustablecol[key1]['tsconstrained'] == '':
            statustablecol[key1]['initialopt'] = colored('done','yellow',None)
        elif statustablecol[key1]['tsconstrained'] == 'done' and statustablecol[key1]['tsopt'] == '':
            statustablecol[key1]['tsconstrained'] = colored('done','green',None)
        elif statustablecol[key1]['tsopt'] == 'done' and statustablecol[key1]['irc1'] == '':
            statustablecol[key1]['tsopt'] = colored('done','green',None)
    df = pd.DataFrame.from_dict(statustablecol,orient='index')
    df = df[['initialopt','tsconstrained','tsopt','irc1','irc2']]
    print(tabulate.tabulate(df,headers=df.columns))
else:
    df = pd.DataFrame.from_dict(statustable,orient='index')
    df = df[['initialopt','tsconstrained','tsopt','irc1','irc2']]
    print(df)

