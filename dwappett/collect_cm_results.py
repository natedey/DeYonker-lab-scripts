#!/bin/sh

# Script for collecting results for big CM MD->QM project
# Created DAW 2026-Jan-27
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
import subprocess
from subprocess import Popen, PIPE,STDOUT
from pymol import cmd
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt


# results processing function
def process_cm_results(homedir,dirlabel,framedirs,tsoptdone,irc1done,irc2done,modeltype):
    fdata = {}
    datafile = open(f'{dirlabel}_results.csv','w')
    datafile.write('frame,ligand,size,charge,reactant,product,dGa,dGr,rms_ts-r_all,rms_ts-r_prot,rms_ts-r_wat,rms_p-r_all,rms_p-r_prot,rms_p-r_wat,ts_path,ts_elE,ts_elE+ZPE,ts_thrmE,ts_H,ts_G,ts_Nbasis,ts_Nimag,ts_Gkcal,react_path,react_elE,react_elE+ZPE,react_thrmE,react_H,react_G,react_Nbasis,react_Nimag,react_Gkcal,prod_path,prod_elE,prod_elE+ZPE,prod_thrmE,prod_H,prod_G,prod_Nbasis,prod_Nimag,prod_Gkcal\n')
    errorlog = []
    for f in framedirs:
        print(f)
        # placeholders for values
        fdata[f] = {'ligand': '', 'size': '', 'charge': '', 'reactant': '', 'product': '', 'dGa': '', 'dGr': '', 'tsvals': ['','','','','','','','',''], 'rvals': ['','','','','','','','',''], 'pvals': ['','','','','','','','',''], 'rms_ts-r': ['','',''], 'rms_p-r': ['','','']}
        # get ligand, size, charge for every frame even if not done
        templatepdb = glob.glob(f'{f}/model_*_template.pdb')[0]
        with open(templatepdb,'r') as fp:
            lines = fp.readlines()
            lig = [line.strip().split() for line in lines if 'COR' in line][0]
            fdata[f]['ligand'] = lig[4]+':'+lig[5]
            ligid = lig[5]
            lig = lig[4]+lig[5]
            #fdata[f]['size'] = str(len(fp.readlines()))
            fdata[f]['size'] = lines[-1].split()[1]
        with open(f'{f}/orca.inp','r') as fp:
            xyzline = [line.strip().split() for line in fp.readlines() if '*xyz' in line][0]
            fdata[f]['charge'] = xyzline[1]

        if f in tsoptdone and f in irc1done and f in irc2done:
            os.chdir(f'{f}/tsopt')
            templatepdb = glob.glob('../model_*_template.pdb')[0]
            if not os.path.isfile(f'{f}-{lig}{modeltype}-ts-opt.pdb'):
                out = subprocess.run([f'xyz_to_pdb.py -pdb {templatepdb} -name {f}-{lig}{modeltype}-ts-opt.pdb'],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
            ircpdbs = glob.glob(f'irc*/{f}-{lig}{modeltype}-*-opt.pdb')
            if len(ircpdbs)==2 and len([i.split('/')[0] for i in ircpdbs if 'reactant' in i])==1 and len([i.split('/')[0] for i in ircpdbs if 'product' in i])==1:
                fdata[f]['reactant']=[i.split('/')[0] for i in ircpdbs if 'reactant' in i][0]
                fdata[f]['product']=[i.split('/')[0] for i in ircpdbs if 'product' in i][0]
            else:
                for i in ['irc1','irc2']:
                    os.chdir(i)
                    out = subprocess.run([f'xyz_to_pdb.py -pdb ../{templatepdb} -name {f}-{lig}{modeltype}-{i}-opt.pdb'],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
                    os.chdir('..')
                pdb1 = f'irc1/{f}-{lig}{modeltype}-irc1-opt.pdb'
                pdb2 = f'irc2/{f}-{lig}{modeltype}-irc2-opt.pdb'
                cmd.load(pdb1, 'irc1')
                dist_r1 = cmd.distance('dist_r1',f'irc1///{ligid}/C5',f'irc1///{ligid}/O7')
                dist_p1 = cmd.distance('dist_p1',f'irc1///{ligid}/C1',f'irc1///{ligid}/C9')
                cmd.load(pdb2, 'irc2')
                dist_r2 = cmd.distance('dist_r2',f'irc2///{ligid}/C5',f'irc2///{ligid}/O7')
                dist_p2 = cmd.distance('dist_p2',f'irc2///{ligid}/C1',f'irc2///{ligid}/C9')
                if dist_r1 < dist_p1 and dist_r2 > dist_p2:
                    fdata[f]['reactant'] = 'irc1'
                    fdata[f]['product'] = 'irc2'
                    os.rename(pdb1,f'irc1/{f}-{lig}{modeltype}-reactant-opt.pdb')
                    os.rename(pdb2,f'irc2/{f}-{lig}{modeltype}-product-opt.pdb')
                    cmd.delete('all')
                elif dist_r1 > dist_p1 and dist_r2 < dist_p2:
                    fdata[f]['reactant'] = 'irc2'
                    fdata[f]['product'] = 'irc1'
                    os.rename(pdb1,f'irc1/{f}-{lig}{modeltype}-product-opt.pdb')
                    os.rename(pdb2,f'irc2/{f}-{lig}{modeltype}-reactant-opt.pdb')
                    cmd.delete('all')
                else:
                    cmd.delete('all')
                    errorlog.append(f'{f} - ircs are not distinct as product and reactant, please check!')
                    continue

            # collect rmsds
            cmd.load(f'{f}-{lig}{modeltype}-ts-opt.pdb','ts')
            cmd.load(f'{fdata[f]["reactant"]}/{f}-{lig}{modeltype}-reactant-opt.pdb','r')
            cmd.load(f'{fdata[f]["product"]}/{f}-{lig}{modeltype}-product-opt.pdb','p')
            for i in ['ts','p']:
                fdata[f][f'rms_{i}-r'][0] = str(round(cmd.rms_cur(i,'r'),2))
                fdata[f][f'rms_{i}-r'][1] = str(round(cmd.rms_cur(f'{i} and not resn COR and not resn WAT', '(r and not resn COR and not resn WAT)'),2))
                fdata[f][f'rms_{i}-r'][2] = str(round(cmd.rms_cur(f'{i} and resn WAT', '(r and resn WAT)'),2))
            cmd.delete('all')

            # collect energies
            out = subprocess.run(['extract-orca.sh'],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
            extracted = [l for l in out.stdout.split('\n') if l]
            Gts = False
            Gr = False
            Gp = False
            for line in extracted:
                line = line.split()
                dirsplit = [d for d in line[0].split('/') if d]
                gkcal = float(line[5])*627.51
                if dirsplit[-1] == 'tsopt':
                    fdata[f]['tsvals'] = line + [str(gkcal)]
                    Gts = gkcal
                elif dirsplit[-1] == fdata[f]['reactant']:
                    fdata[f]['rvals'] = line + [str(gkcal)]
                    Gr = gkcal
                elif dirsplit[-1] == fdata[f]['product']:
                    fdata[f]['pvals'] = line + [str(gkcal)]
                    Gp = gkcal
            if Gts and Gr and Gp:
                fdata[f]['dGa'] = str(Gts - Gr)
                fdata[f]['dGr'] = str(Gp - Gr)
            else:
                errorlog.append(f'{f} - extract-orca.sh output not parsed as expected, please check outputs!')

            
        
#line info will be: frame, ligand, size, charge, reactant irc, product irc, calculated dGa, calculated dGr, rmsds [3x2 = 6cols], extract-orca outputs with G kcal/mol [9x3 = 24 cols]
        lineinfo = [f] + [fdata[f][i] for i in ['ligand','size','charge','reactant','product','dGa','dGr']] + fdata[f]['rms_ts-r'] + fdata[f]['rms_p-r'] + fdata[f]['tsvals'] + fdata[f]['rvals'] + fdata[f]['pvals']
        lineinfo = ','.join(lineinfo)
        
        # write csv line
        os.chdir(homedir)
        datafile.write(lineinfo+'\n')

    datafile.close()
    if errorlog:
        with open(f'{dirlabel}_collection_errors.txt') as fp:
            fp.write('\n'.join(errorlog))

    return fdata


### make quick plot ###
def plotcollectedresults(dirlabel):
    df = pd.read_csv(f'{dirlabel}_results.csv',index_col='frame')
    df.insert(loc=0, column='fnum', value=[int(i.replace('f','')) for i in df.index.values])
    fig, axs = plt.subplots(nrows=2,ncols=1,figsize=(10,6),layout='constrained')
    line1 = axs[0].hlines(df['dGa'].mean(),df['fnum'].min()-1,df['fnum'].max()+1,colors='k',linestyles='dashed',label=r"mean $\Delta G ^\ddagger$"+f" = {df['dGa'].mean().round(2)} kcal/mol")
    line2 = axs[1].hlines(df['dGr'].mean(),df['fnum'].min()-1,df['fnum'].max()+1,colors='k',linestyles='dashed',label=r"mean $\Delta G _{rxn}$"+f" = {df['dGr'].mean().round(2)} kcal/mol")
    df.plot(x='fnum',y='dGa',kind='scatter',ax=axs[0],ylabel=r'$\Delta G ^\ddagger$ (kcal/mol)',marker='o',color='b',xlabel='',xlim=(df['fnum'].min()-1,df['fnum'].max()+1))
    df.plot(x='fnum',y='dGr',kind='scatter',ax=axs[1],ylabel=r'$\Delta G _{rxn}$ (kcal/mol)',marker='^',color='r',xlabel='model/frame number',xlim=(df['fnum'].min()-1,df['fnum'].max()+1))
    axs[0].legend(handles=[line1],loc='best')
    axs[1].legend(handles=[line2],loc='best')
    fig.align_labels()
    plt.savefig(f'{dirlabel}_free_energies.png')



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="collect ts/irc1/irc2 energies and calculate free energies of activation/reaction and convert optimized strucs to pdb format for big CM MD->QM project")
    parser.add_argument('-dir',dest='workdir',default='.',help='directory to collect results for, default = current dir')
    parser.add_argument('-batch',action='store_true',help='label collected results as being from batch models instead of individual')
    args = parser.parse_args()

    os.chdir(args.workdir)
    homedir = os.getcwd()
    dirlabel = os.getcwd().split('/')[-2]+'_'+os.getcwd().split('/')[-1]
    framedirs=glob.glob('f*')
    framedirs.sort()
    tsoptdone = [line.split('/')[0] for line in open('check_tsopt_done.txt','r').readlines()]
    irc1done = [line.split('/')[0] for line in open('check_irc1_done.txt','r').readlines()]
    irc2done = [line.split('/')[0] for line in open('check_irc2_done.txt','r').readlines()]
    if args.batch:
        modeltype = 'batch'
    else:
        modeltype = ''

    fdata = process_cm_results(homedir,dirlabel,framedirs,tsoptdone,irc1done,irc2done,modeltype)
    plotcollectedresults(dirlabel)    
