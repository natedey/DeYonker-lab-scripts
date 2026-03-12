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
import time
import subprocess
from subprocess import Popen, PIPE,STDOUT
from pymol import cmd
from read_write_pdb import read_pdb
from model_details import get_model_FGs
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt

### quick function to get list of all imag modes (only needed for ircs) ###
def get_orca_imag_modes(outfile):
    out = subprocess.run(['tac '+outfile+' | grep -m 1 -B 30 "VIBRATIONAL FREQUENCIES" | grep "imaginary mode" | awk \'{print $2}\''],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
    modelist = [float(m) for m in out.stdout.split('\n') if m]
    modelist.sort()
    return modelist

### main results processing function ###
def process_cm_results(homedir,dirlabel,framedirs,tsoptdone,irc1done,irc2done,modeltype):
    # list of things to collect that will become dataframe column names. defining this first makes it easier to keep track of what we're collecting/organise order of df columns from the start
    # how I've organised the list: most basic/important stuff first (model/size/charge/free energies), then structural stuff (dists/rmsds/movement during opt), then individual struc energies
    vals=['fnum','ligand', 'size', 'charge', 'done', 'reactant', 'product', 'dGa', 'dGr', 
            #'ts_mode', 
            'ts_C1-C9_dist', 'ts_C5-O7_dist', 'r_C1-C9_dist', 'r_C5-O7_dist', 'p_C1-C9_dist', 'p_C5-O7_dist', 'r_C1-C5-O7-C9_dihedral', 'p_C5-C1-C9-O7_dihedral',
            'rms_tmp-init_all', 'rms_tmp-init_prot', 'rms_tmp-init_wat', 'rms_guess-ts_all', 'rms_guess-ts_prot', 'rms_guess-ts_wat',
            'rms_ts-r_all', 'rms_ts-r_prot', 'rms_ts-r_wat', 'rms_p-r_all', 'rms_p-r_prot', 'rms_p-r_wat', 'rms_ts-p_all', 'rms_ts-p_prot', 'rms_ts-p_wat',
            'maxmove_H_tmp-init', 'maxmove_H_guess-ts', 'maxmove_H_ts-r', 'maxmove_H_ts-p', 'maxmove_heavy_tmp-init', 'maxmove_heavy_guess-ts', 'maxmove_heavy_ts-r', 'maxmove_heavy_ts-p',
            'ts_path', 'ts_elE', 'ts_elE+ZPE', 'ts_thrmE', 'ts_H', 'ts_G', 'ts_Nbasis', 'ts_Nimag', 'ts_Gkcal', 'ts_imagmodes',
            'r_path', 'r_elE', 'r_elE+ZPE', 'r_thrmE', 'r_H', 'r_G', 'r_Nbasis', 'r_Nimag', 'r_Gkcal', 'r_imagmodes',
            'p_path', 'p_elE', 'p_elE+ZPE', 'p_thrmE', 'p_H', 'p_G', 'p_Nbasis', 'p_Nimag', 'p_Gkcal', 'p_imagmodes']
    extractvals=['path', 'elE', 'elE+ZPE', 'thrmE', 'H', 'G', 'Nbasis', 'Nimag'] # labels for output of extract_orca.sh, match the ts/react/prod prefixed values above
    fdata = {}      # dictionary to collect all data into
    modelFGs = {}   # dictionary to collect all model contents into
    errorlog = []   # list to collect any error messages

    for f in framedirs:
        print(f)
        fdata[f] = {i: '' for i in vals}    # placeholders for values
        for i in ['ts_imagmodes','r_imagmodes','p_imagmodes']: fdata[f][i] = []     # replace string placeholders with list placeholders for these
        fdata[f]['fnum'] = int(f.replace('f',''))
        
        ### get ligand, size, charge for every model even if not done ###
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
        ### also get FG list
        FGs = get_model_FGs(templatepdb,[fdata[f]['ligand']])
        FGs = [i[0]+':'+i[1] for i in FGs]
        modelFGs[f] = {g: 1 for g in FGs}

        ### collect full results for models that are fully done ###
        if f in tsoptdone and f in irc1done and f in irc2done:
            os.chdir(f'{f}/tsopt')
            templatepdb = glob.glob('../model_*_template.pdb')[0]   # redefine templatepdb relative to new current dir
            
            ### convert optimised ts/irc1/irc2 strucs back to pdb format with clear/unique names if not already done ###
            ### also determine which irc is reactant and which is product so results can be labeled more clearly ###
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
                ### dist_r < dist_p indicates reactant, dist_p < dist_r indicates product. use these distances to determine which irc is which ###
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

            ### collect structural info ###
            # load relevant structures as pymol objects
            cmd.load(glob.glob('../model_*_template.pdb')[0],'tmp')
            cmd.load(f'../{f}-opt.pdb','init')
            cmd.load(f'../tsconstrained/tsguess.pdb','guess')
            cmd.load(f'{f}-{lig}{modeltype}-ts-opt.pdb','ts')
            cmd.load(f'{fdata[f]["reactant"]}/{f}-{lig}{modeltype}-reactant-opt.pdb','r')
            cmd.load(f'{fdata[f]["product"]}/{f}-{lig}{modeltype}-product-opt.pdb','p')
            # read and process pdb to get lists of all atoms in strucs 
            pdb, res_info, tot_charge = read_pdb(f'{f}-{lig}{modeltype}-ts-opt.pdb')
            allH = [f'{line[5]}/{line[6]}/{line[2].strip()}' for line in pdb if line[2].strip().startswith('H')]
            allheavy = [f'{line[5]}/{line[6]}/{line[2].strip()}' for line in pdb if not line[2].strip().startswith('H')]
            # get "product bond" (C1-C9) and "reactant bond" (C5-O7) distances for each struc
            for i in ['ts','r','p']:
                fdata[f][f'{i}_C1-C9_dist'] = str(round(cmd.get_distance(f'{i} and resn COR and name C1', f'{i} and resn COR and name C9'),2))
                fdata[f][f'{i}_C5-O7_dist'] = str(round(cmd.get_distance(f'{i} and resn COR and name C5', f'{i} and resn COR and name O7'),2))
            # get specific dihedral for reactant and product
            fdata[f]['r_C1-C5-O7-C9_dihedral'] = str(round(cmd.get_dihedral(f'r///{ligid}/C1',f'r///{ligid}/C5',f'r///{ligid}/O7',f'r///{ligid}/C9'),2))
            fdata[f]['p_C5-C1-C9-O7_dihedral'] = str(round(cmd.get_dihedral(f'p///{ligid}/C5',f'p///{ligid}/C1',f'p///{ligid}/C9',f'p///{ligid}/O7'),2))
            # define pairs of strucs and then compare them: rmsds and the biggest difference in position ("maxmove") for any individual atom
            for i in [('tmp','init'),('guess','ts'),('ts','r'),('p','r'),('ts','p')]:
                fdata[f][f'rms_{i[0]}-{i[1]}_all'] = str(round(cmd.rms_cur(i[0],i[1]),2))
                fdata[f][f'rms_{i[0]}-{i[1]}_prot'] = str(round(cmd.rms_cur(f'{i[0]} and not resn COR and not resn WAT', f'({i[1]} and not resn COR and not resn WAT)'),2))
                fdata[f][f'rms_{i[0]}-{i[1]}_wat'] = str(round(cmd.rms_cur(f'{i[0]} and resn WAT', f'({i[1]} and resn WAT)'),2))
                Hdists = [cmd.get_distance(f'{i[0]}//{hydro}',f'{i[1]}//{hydro}') for hydro in allH]                
                fdata[f][f'maxmove_H_{i[0]}-{i[1]}'] = str(round(max(Hdists),2))
                heavydists = [cmd.get_distance(f'{i[0]}//{heavy}',f'{i[1]}//{heavy}') for heavy in allheavy]
                fdata[f][f'maxmove_heavy_{i[0]}-{i[1]}'] = str(round(max(heavydists),2))
            cmd.delete('all')   # delete all pymol objects so nothing left to potentially interfere with next iteration

            ### collect TS imaginary mode. also noted in extract-orca.sh but need extra fiddly command to avoid grabbing stuff from any (re)calc_hess vib blocks before opt converged
            #out = subprocess.run(['tac orca.out | grep -m 1 -B 30 "VIBRATIONAL FREQUENCIES" | grep " 6: " | awk \'{print $2}\''],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
            #fdata[f]['ts_mode'] = out.stdout.strip()

            ### collect and process energies ###
            out = subprocess.run(['extract-orca.sh'],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
            extracted = [l for l in out.stdout.split('\n') if l]    # clean up output
            # failsafe to avoid miscalculating deltaG with previous iteration's vals if anything goes wrong with extraction
            Gts = False
            Gr = False
            Gp = False
            for line in extracted:
                line = line.split()
                dirsplit = [d for d in line[0].split('/') if d]
                gkcal = float(line[5])*627.51
                if dirsplit[-1] == 'tsopt':
                    # for each value in line, get descriptor from extractvals list and use to add to data dict
                    for i,v in enumerate(line):
                        fdata[f][f'ts_{extractvals[i]}'] = v
                    fdata[f]['ts_Gkcal'] = str(gkcal)
                    Gts = gkcal
                    fdata[f]['ts_imagmodes'] = get_orca_imag_modes('orca.out')
                elif dirsplit[-1] == fdata[f]['reactant']:
                    for i,v in enumerate(line):
                        fdata[f][f'r_{extractvals[i]}'] = v
                    fdata[f]['r_Gkcal'] = str(gkcal)
                    Gr = gkcal
                    fdata[f]['r_imagmodes'] = get_orca_imag_modes(dirsplit[-1]+'/orca.out')
                elif dirsplit[-1] == fdata[f]['product']:
                    for i,v in enumerate(line):
                        fdata[f][f'p_{extractvals[i]}'] = v
                    fdata[f]['p_Gkcal'] = str(gkcal)
                    Gp = gkcal
                    fdata[f]['p_imagmodes'] = get_orca_imag_modes(dirsplit[-1]+'/orca.out')
            if Gts and Gr and Gp:   # second part of failsafe: only calculate deltaGs if all G values collected properly (no False placeholders left)
                fdata[f]['dGa'] = str(Gts - Gr)
                fdata[f]['dGr'] = str(Gp - Gr)
                fdata[f]['done'] = 'Y'
            else:
                errorlog.append(f'{f} - extract-orca.sh output not parsed as expected, please check outputs!')
        
        os.chdir(homedir)

    ### make results csv ###
    # note that all values in df here are strings to avoid weird mismatched data types in incomplete columns
    # don't waste time messing with numerical data types to make df directly useable for plotting. save as csv, then more sensible data types will be set automatically when loading from csv :D
    df = pd.DataFrame.from_dict(fdata,orient='index')
    df.to_csv(f'{dirlabel}_results.csv',index_label='frame')

    ### make FG csv ###
    df2 = pd.DataFrame.from_dict(modelFGs,orient='index')
    df2.to_csv(f'{dirlabel}_model_FGs.csv',index_label='frame')

    ### make error log file if any errors ###
    if errorlog:
        with open(f'{dirlabel}_collection_errors.txt') as fp:
            fp.write('\n'.join(errorlog))

    return fdata


### function to make quick plot ###
def plotcollectedresults(dirlabel):
    # read back in from csv so numerical data is actually numerical or your axes will look weird
    df = pd.read_csv(f'{dirlabel}_results.csv',index_col='frame')
    # set up plots
    fig, axs = plt.subplots(nrows=2,ncols=1,figsize=(10,6),layout='constrained')
    # plot mean values as lines
    line1 = axs[0].hlines(df['dGa'].mean(),df['fnum'].min()-1,df['fnum'].max()+1,colors='k',linestyles='dashed',label=r"mean $\Delta G ^\ddagger$"+f" = {df['dGa'].mean().round(2)} kcal/mol")
    line2 = axs[1].hlines(df['dGr'].mean(),df['fnum'].min()-1,df['fnum'].max()+1,colors='k',linestyles='dashed',label=r"mean $\Delta G _{rxn}$"+f" = {df['dGr'].mean().round(2)} kcal/mol")
    # plot values
    df.plot(x='fnum',y='dGa',kind='scatter',ax=axs[0],ylabel=r'$\Delta G ^\ddagger$ (kcal/mol)',marker='o',color='b',xlabel='',xlim=(df['fnum'].min()-1,df['fnum'].max()+1))
    df.plot(x='fnum',y='dGr',kind='scatter',ax=axs[1],ylabel=r'$\Delta G _{rxn}$ (kcal/mol)',marker='^',color='r',xlabel='model/frame number',xlim=(df['fnum'].min()-1,df['fnum'].max()+1))
    # add legends with max vals
    axs[0].legend(handles=[line1],loc='best')
    axs[1].legend(handles=[line2],loc='best')
    fig.align_labels()
    plt.savefig(f'{dirlabel}_free_energies.png')



if __name__ == '__main__':
    st = time.perf_counter()
    
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
    # plot function is actually independent of results collection, only reads the data from the saved csv file not the original df
    # you can temporarily comment out the line above to skip slow collection step if you're just tweaking features of the output plot
    plotcollectedresults(dirlabel)

    et = time.perf_counter()
    seconds = et-st
    m, s = divmod(seconds, 60)
    print(f'Completed in {int(m)} minute(s) and {int(s)} second(s)')
