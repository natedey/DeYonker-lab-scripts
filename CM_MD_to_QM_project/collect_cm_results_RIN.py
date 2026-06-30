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
from probe2rins import atom_split
import pandas as pd
import matplotlib
import math
import matplotlib.pyplot as plt
import networkx as nx

### quick function to get list of all imag modes for tsopts/ircs ###
# noted in extract-orca.sh and check_cm_jobs.sh but reminder that we have to get the final imag modes this way to avoid also grabbing stuff from partway (re)calc_hess steps
def get_orca_imag_modes(outfile):
    out = subprocess.run(['tac '+outfile+' | grep -m 1 -B 30 "VIBRATIONAL FREQUENCIES" | grep "imaginary mode" | awk \'{print $2}\''],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
    modelist = [float(m) for m in out.stdout.split('\n') if m]
    modelist.sort()
    return modelist

### quick function for identifying hbonds with probe ###
def get_probe_hbonds(pdbfile):
    # run probe if probe file not already present
    probefile = pdbfile.replace('.pdb','.probe')
    if not os.path.isfile(probefile):
        probepath = os.path.expanduser('~/git/RINRUS/bin/probe')
        probeargs = [f'{probepath} -unformated -MC -self "all" -Quiet {pdbfile} > {probefile}']
        out = subprocess.run(probeargs,shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
        if out.returncode == 1:
            errorlog.append(f'error running probe for {pdbfile}')
            return None, errorlog
    # read in probe file, extract just hbond lines
    lines = open(probefile,'r').readlines()
    lines = [line.strip() for line in lines if ':hb:' in line]
    # setting this up as a dict to keep contact count info too in case you think of a way to use that
    hb_pairs = {}
    for line in lines:
        line = line.split(':')
        at1 = atom_split(line[3])
        at2 = atom_split(line[4])
        # formatting atoms in pair as ch/id/atname to match pymol selection macro so it'll be super easy to get their distances if you want them 
        if int(at1[1]) < int(at2[1]):
            ordered_pair = (f'{at1[0]}/{at1[1]}/{at1[3]}',f'{at2[0]}/{at2[1]}/{at2[3]}')
        else:
            ordered_pair = (f'{at2[0]}/{at2[1]}/{at2[3]}',f'{at1[0]}/{at1[1]}/{at1[3]}')
        if ordered_pair not in hb_pairs.keys():
            hb_pairs[ordered_pair] = 1
        else:
            hb_pairs[ordered_pair] += 1
    return hb_pairs

def get_RIN_analysis(pdbfile):
    lines = open(pdbfile, 'r').readlines()
    lines = [line.strip() for line in lines if "CA" in line]
    G = nx.Graph()
    nodes_list = []
    coordinates_list = []
    for line in lines:
        chain = line[21].strip()
        res_id = line[23:27].strip()
        res_name = line[17:20].strip()
        coordinates = line[31:52].strip()
        node = f"{res_name}_{res_id}"
        nodes_list.append(node)
        coordinates_list.append(coordinates)
        G.add_node(node, pos=coordinates)
    for i in (range(len(nodes_list))):
        for j in range(i+1, len(nodes_list)):
            atom1= nodes_list[i]
            atom2= nodes_list[j]
            coordinates1_str = coordinates_list[i]
            coordinates2_str = coordinates_list[j]
            c1 = [float(x) for x in coordinates1_str.split()]
            c2 = [float(x) for x in coordinates2_str.split()]
            distance = math.sqrt(((c1[0]-c2[0])**2 + (c1[1]-c2[1])**2 + (c1[2]-c2[2])**2))
            if distance <= 7.0:
                G.add_edge(atom1, atom2, weight=distance)
    return G

### main results processing function ###
def process_cm_results(homedir,dirlabel,framedirs,tsoptdone,irc1done,irc2done,modeltype):
    # list of things to collect that will become dataframe column names. defining this first makes it easier to keep track of what we're collecting/organise order of df columns from the start
    # how I've organised the list: most basic/important stuff first (model/size/charge/free energies), then structural stuff (dists/rmsds/movement during opt), then individual struc energies
    vals = ['fnum', 'ligand', 'size', 'charge', 'done', 'reactant', 'product', 'ts_type', 'dGa', 'dGr', 
            'ts_C1-C9_dist', 'ts_C5-O7_dist', 'r_C1-C9_dist', 'r_C5-O7_dist', 'p_C1-C9_dist', 'p_C5-O7_dist', 'r_C1-C5-O7-C9_dihedral', 'p_C5-C1-C9-O7_dihedral',
            'rms_tmp-init_all', 'rms_tmp-init_lig', 'rms_tmp-init_prot', 'rms_tmp-init_wat', 'rms_guess-ts_all','rms_guess-ts_lig', 'rms_guess-ts_prot', 'rms_guess-ts_wat', 'rms_r-init_all', 'rms_r-init_lig', 'rms_r-init_prot', 'rms_r-init_wat',
            'rms_ts-r_all', 'rms_ts-r_lig', 'rms_ts-r_prot', 'rms_ts-r_wat', 'rms_p-r_all', 'rms_p-r_lig', 'rms_p-r_prot', 'rms_p-r_wat', 'rms_ts-p_all', 'rms_ts-p_lig', 'rms_ts-p_prot', 'rms_ts-p_wat',
            'rms_tmp-f00001tmp_all', 'rms_tmp-f00001tmp_SC', 'rms_tmp-f00001tmp_MC', 'rms_init-f00001init_all', 'rms_init-f00001init_SC', 'rms_init-f00001init_MC', 'rms_ts-f00001ts_all', 'rms_ts-f00001ts_SC', 'rms_ts-f00001ts_MC', 'rms_r-f00001r_all', 'rms_r-f00001r_SC', 'rms_r-f00001r_MC', 'rms_p-f00001p_all', 'rms_p-f00001p_SC', 'rms_p-f00001p_MC',
            'maxmove_H_tmp-init', 'maxmove_H_guess-ts', 'maxmove_H_ts-r', 'maxmove_H_ts-p', 'maxmove_H_p-r', 'maxmove_H_r-init', 
            'maxmove_heavy_tmp-init', 'maxmove_heavy_guess-ts', 'maxmove_heavy_ts-r', 'maxmove_heavy_ts-p', 'maxmove_heavy_p-r', 'maxmove_heavy_r-init',
            'maxmove_diff_tmp-init', 'maxmove_diff_guess-ts', 'maxmove_diff_ts-r', 'maxmove_diff_ts-p', 'maxmove_diff_p-r', 'maxmove_diff_r-init', 'Hdetached',
            'Nhb_ts_all', 'Nhb_ts_lig', 'Nhb_r_all', 'Nhb_r_lig', 'Nhb_p_all', 'Nhb_p_lig', 'hb_HO5_ts_fg', 'hb_HO5_ts_dist', 'hb_HO5_r_fg', 'hb_HO5_r_dist', 'hb_HO5_p_fg', 'hb_HO5_p_dist',
            'hb_ts_lig-Arg63', 'hb_r_lig-Arg63', 'hb_p_lig-Arg63', 'hb_ts_lig-Arg7', 'hb_r_lig-Arg7', 'hb_p_lig-Arg7','hb_ts_lig-Arg90','hb_r_lig-Arg90','hb_p_lig-Arg90',
            'ts_path', 'ts_elE', 'ts_elE+ZPE', 'ts_thrmE', 'ts_H', 'ts_G', 'ts_Nbasis', 'ts_Nimag', 'ts_Gkcal', 'ts_imagmodes',
            'r_path', 'r_elE', 'r_elE+ZPE', 'r_thrmE', 'r_H', 'r_G', 'r_Nbasis', 'r_Nimag', 'r_Gkcal', 'r_imagmodes',
            'p_path', 'p_elE', 'p_elE+ZPE', 'p_thrmE', 'p_H', 'p_G', 'p_Nbasis', 'p_Nimag', 'p_Gkcal', 'p_imagmodes',
            'init_elE', 'dE_r-init']
    extractvals = ['path', 'elE', 'elE+ZPE', 'thrmE', 'H', 'G', 'Nbasis', 'Nimag'] # labels for output of extract_orca.sh, match the ts/react/prod prefixed values above
    fdata = {}      # dictionary to collect all data into
    modelFGs = {}   # dictionary to collect all model contents into
    errorlog = []   # list to collect any error messages

    # load f00001 strucs as pymol objects for comparisons. DAW needs to figure out how to make this work for the individual models in her own dirs...
    if modeltype == '' and os.path.isdir('../f00001-f00010/f00001/'):
        cmd.load(glob.glob('../f00001-f00010/f00001/model_*_template.pdb')[0],'f00001tmp')
        cmd.load('../f00001-f00010/f00001/f00001-opt.pdb','f00001init')
        cmd.load(glob.glob('../f00001-f00010/f00001/tsopt/*-ts-opt.pdb')[0],'f00001ts')
        cmd.load(glob.glob('../f00001-f00010/f00001/tsopt/irc*/*-reactant-opt.pdb')[0],'f00001r')
        cmd.load(glob.glob('../f00001-f00010/f00001/tsopt/irc*/*-product-opt.pdb')[0],'f00001p')
        first_loaded = True
    else:
        first_loaded = False

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
            ### also check how ts was obtained: normal/newguess/newguess-directopt ###
            ### and determine which irc is reactant and which is product so results can be labeled more clearly ###
            if not os.path.isfile(f'{f}-{lig}{modeltype}-ts-opt.pdb'):
                out = subprocess.run([f'xyz_to_pdb.py -pdb {templatepdb} -name {f}-{lig}{modeltype}-ts-opt.pdb'],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
            if os.path.isdir('../original-tsguess-tsconstrained') and os.path.isdir('../original-tsguess-tsopt') and os.path.isdir('../tsopt-failed'):
                fdata[f]['ts_type'] = 'newguess-directopt'
            elif os.path.isdir('../original-tsguess-tsconstrained') and os.path.isdir('../original-tsguess-tsopt'):
                fdata[f]['ts_type'] = 'newguess'
            else:
                fdata[f]['ts_type'] = 'normal'
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
                    #cmd.delete('all')
                    for obj in [n for n in cmd.get_names("all") if 'f00001' not in n]: cmd.delete(obj)
                elif dist_r1 > dist_p1 and dist_r2 < dist_p2:
                    fdata[f]['reactant'] = 'irc2'
                    fdata[f]['product'] = 'irc1'
                    os.rename(pdb1,f'irc1/{f}-{lig}{modeltype}-product-opt.pdb')
                    os.rename(pdb2,f'irc2/{f}-{lig}{modeltype}-reactant-opt.pdb')
                    #cmd.delete('all')
                    for obj in [n for n in cmd.get_names("all") if 'f00001' not in n]: cmd.delete(obj)
                else:
                    #cmd.delete('all')
                    for obj in [n for n in cmd.get_names("all") if 'f00001' not in n]: cmd.delete(obj)
                    errorlog.append(f'{f} - ircs are not distinct as product and reactant, please check!')
                    os.chdir(homedir)
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
            for i in [('tmp','init'),('guess','ts'),('ts','r'),('p','r'),('ts','p'),('r','init')]:
                fdata[f][f'rms_{i[0]}-{i[1]}_all'] = str(round(cmd.rms_cur(i[0],i[1]),2))
                fdata[f][f'rms_{i[0]}-{i[1]}_lig'] = str(round(cmd.rms_cur(f'{i[0]} and resn COR', f'({i[1]} and resn COR)'),2))
                fdata[f][f'rms_{i[0]}-{i[1]}_prot'] = str(round(cmd.rms_cur(f'{i[0]} and not resn COR and not resn WAT', f'({i[1]} and not resn COR and not resn WAT)'),2))
                fdata[f][f'rms_{i[0]}-{i[1]}_wat'] = str(round(cmd.rms_cur(f'{i[0]} and resn WAT', f'({i[1]} and resn WAT)'),2))
                Hdists = [cmd.get_distance(f'{i[0]}//{hydro}',f'{i[1]}//{hydro}') for hydro in allH]                
                heavydists = [cmd.get_distance(f'{i[0]}//{heavy}',f'{i[1]}//{heavy}') for heavy in allheavy]
                fdata[f][f'maxmove_H_{i[0]}-{i[1]}'] = str(round(max(Hdists),2))
                fdata[f][f'maxmove_heavy_{i[0]}-{i[1]}'] = str(round(max(heavydists),2))
                fdata[f][f'maxmove_diff_{i[0]}-{i[1]}'] = str(round(max(Hdists)-max(heavydists),2))
            # find what each H in template pdb is covalently bound to (= closest heavy atom with same residue id)
            H_bound_tmp = {}
            for i in allH:
                res_heavy = [j for j in allheavy if i.rsplit('/',1)[0] in j]
                heavydists_tmp = {j: cmd.get_distance(f'tmp//{i}',f'tmp//{j}') for j in res_heavy}
                H_bound_tmp[(i,min(heavydists_tmp,key=heavydists_tmp.get))] = heavydists_tmp[min(heavydists_tmp,key=heavydists_tmp.get)]
            for struc in ['init','ts','r','p']:
                # check if any of the pairs that should be bound have distance > 1.1 * original dist (just allowing for slight variations between amberff and xtb)
                # when an unbound pair is found, log the struc and move to the next one (don't need to waste time checking rest of pairs)
                for pair in H_bound_tmp.keys():
                    if cmd.get_distance(f'{struc}//{pair[0]}',f'{struc}//{pair[1]}') > (H_bound_tmp[pair] * 1.1):
                        if fdata[f]['Hdetached'] == '':
                            fdata[f]['Hdetached'] = struc
                        else:
                            fdata[f]['Hdetached'] = fdata[f]['Hdetached']+','+struc
                        break 
                     
            # rmsds to f00001 as well
            if first_loaded:
                MC_atom_names = '(name C or name CA or name N or name O or name H)'
                for i in ['tmp','init','ts','r','p']:
                    fdata[f][f'rms_{i}-f00001{i}_all'] = str(round(cmd.rms_cur(i,f'f00001{i}'),2))
                    fdata[f][f'rms_{i}-f00001{i}_SC'] = str(round(cmd.rms_cur(f'{i} and not resn COR and not resn WAT and not {MC_atom_names}', f'(f00001{i} and not resn COR and not resn WAT and not {MC_atom_names})'),2))
                    fdata[f][f'rms_{i}-f00001{i}_MC'] = str(round(cmd.rms_cur(f'{i} and not resn COR and not resn WAT and {MC_atom_names}', f'(f00001{i} and not resn COR and not resn WAT and {MC_atom_names})'),2))
            
            # get hbonds from probe and count
            # to see what the steps are doing, run my test script here:     /project/dwappett/chorismate_mutase/QM-batch-models/A128-every-100th/test-hbond-analysis.py
            hbpairs = {}
            hbpairs['ts'] = get_probe_hbonds(f'{f}-{lig}{modeltype}-ts-opt.pdb')
            hbpairs['r'] = get_probe_hbonds(f'{fdata[f]["reactant"]}/{f}-{lig}{modeltype}-reactant-opt.pdb')
            hbpairs['p'] = get_probe_hbonds(f'{fdata[f]["product"]}/{f}-{lig}{modeltype}-product-opt.pdb')
            for i in ['ts','r','p']:
                if hbpairs[i]:
                    fdata[f][f'Nhb_{i}_all'] = len(hbpairs[i].keys())
                    fdata[f][f'Nhb_{i}_lig'] = len([p for p in hbpairs[i].keys() if ligid in p[0] or ligid in p[1]])
            networkx = {}
            networkx['ts'] = get_RIN_analysis(f'{f}-{lig}{modeltype}-ts-opt.pdb')
            networkx['r'] = get_RIN_analysis(f'{fdata[f]["reactant"]}/{f}-{lig}{modeltype}-reactant-opt.pdb')
            networkx['p'] = get_RIN_analysis(f'{fdata[f]["product"]}/{f}-{lig}{modeltype}-product-opt.pdb')
            for i in ['ts', 'r', 'p']:
                if networkx[i] is not None:
                    G_graph = networkx[i]
                    DC_analysis = nx.degree_centrality(G_graph)
                    BC_analysis = nx.betweenness_centrality(G_graph, normalized=True)
                    CC_analysis = nx.closeness_centrality(G_graph, distance='weight')
                    BC_residues = sorted(BC_analysis.items(), key=lambda x: x[1], reverse=True)
                    CC_residues = sorted(CC_analysis.items(), key=lambda x: x[1], reverse=True)
                    DC_residues = sorted(DC_analysis.items(), key=lambda x: x[1], reverse=True)
                    fdata[f][f'{i}_BC'] = str(BC_residues)
                    fdata[f][f'{i}_CC'] = str(CC_residues)
                    fdata[f][f'{i}_DC'] = str(DC_residues)
                else :
                    fdata[f][f'{i}_BC'] = 'N/A'
                    fdata[f][f'{i}_CC'] = 'N/A'
                    fdata[f][f'{i}_DC'] = 'N/A'
            ##########################################################################################
            ###                   ADD NEW COMMANDS (EG DISTANCES, ANGLES) HERE                     ###            

            # look for specific hbonds in the probe hbonds lists for each structure
            for i in ['ts','r','p']:
                if hbpairs[i]:
                    # seeing where ligand HO5 is pointing/getting distance of h-bond if there is one
                    HO5_hb = [p for p in hbpairs[i].keys() if f'{ligid}/HO5' in p[0] or f'{ligid}/HO5' in p[1]]
                    # if there is h-bond involving HO5 identified, get the other element of the pair and then distance between the atoms
                    if HO5_hb: 
                        other_atom = [at for at in HO5_hb[0] if ligid not in at or 'HO5' not in at][0]
                        fdata[f][f'hb_HO5_{i}_fg'] = other_atom
                        fdata[f][f'hb_HO5_{i}_dist'] = str(round(cmd.get_distance(f'{i}///{ligid}/HO5', f'{i}//{other_atom}'),2))
                    else: #specifically label if no h-bond so that can be seen in plots (empty values/nans get ignored)
                        fdata[f][f'hb_HO5_{i}_fg'] = 'none'

                    # DAW demonstrated in group meeting April 30th: check hbonds between ligand and Arg63  
                    # first need to determine what the correct ch/id label is depending on the ligand
                    if ligid == '128': arg = 'C/319'
                    elif ligid == '256': arg = 'A/63'
                    elif ligid == '384': arg = 'B/191'
                    # get all probe h-bonds between arg and ligand
                    argpairs = [p for p in hbpairs[i].keys() if (arg in p[0] and ligid in p[1]) or (arg in p[1] and ligid in p[0])]
                    # log number of arg-lig h-bonds; if 2 h-bonds then also note if both to same O or one to each O
                    if len(argpairs) == 2:
                        ligatom0 = [atom for atom in argpairs[0] if ligid in atom]
                        ligatom1 = [atom for atom in argpairs[1] if ligid in atom]
                        if ligatom0 == ligatom1:
                            fdata[f][f'hb_{i}_lig-Arg63'] = '2hb-sameO'
                        else:
                            fdata[f][f'hb_{i}_lig-Arg63'] = '2hb-diffO'
                    else:
                        fdata[f][f'hb_{i}_lig-Arg63'] = f'{len(argpairs)}hb'

                    # Duplicate section above but for Arg7, col names already added into vars list at top for you
                    #if ligid == '128': arg = 'A/7'
                    #modifications made by Pedro Garber 5th of June
                    if ligid == '384': arg = 'C/263'
                    elif ligid == '128': arg = 'A/7'
                    elif ligid == '256': arg = 'B/135'
                    argpairs = [p for p in hbpairs[i].keys() if (arg in p[0] and ligid in p[1]) or (arg in p[1] and ligid in p[0])]
                    if len(argpairs) == 2:
                        ligatom0 = [atom for atom in argpairs[0] if ligid in atom]
                        ligatom1 = [atom for atom in argpairs[1] if ligid in atom]
                        if ligatom0 == ligatom1:
                            fdata[f][f'hb_{i}_lig-Arg7'] = '2hb-sameO'
                        else:
                            fdata[f][f'hb_{i}_lig-Arg7'] = '2hb-diffO'
                    else:
                        fdata[f][f'hb_{i}_lig-Arg7'] = f'{len(argpairs)}hb'
                    
                    #trying for Arg90 see if has interactions with the substrate
                    if ligid == '384': arg = 'C/346'
                    elif ligid == '128': arg = 'A/90'
                    elif ligid == '256': arg = 'B/218'
                    #get all probe h-bonds between arg and ligand
                    argpairs = [p for p in hbpairs[i].keys() if (arg in p[0] and ligid in p[1]) or (arg in p[1] and ligid in p[0])]
                    fdata[f][f'hb_{i}_lig-Arg90'] = f'{len(argpairs)}hb'
                    arg_chain, arg_resi = arg.split('/')
                    HE_hb = [p for p in hbpairs[i].keys() if f'{arg}/HE' in p[0] or f'{arg}/HE' in p[1]]
                    if HE_hb:
                        other_atom = [at for at in HE_hb[0] if ligid not in at or 'HE' not in at][0]
                        oa_chain, oa_resi, oa_name = other_atom.split('/')
                        
                        sel_arg = f"first (model {i} and chain {arg_chain} and resi {arg_resi} and name HE)"
                        sel_other = f"first (model {i} and chain {oa_chain} and resi {oa_resi} and name {oa_name})"
                        
                        fdata[f][f'hb_HE_{i}_fg'] = other_atom
                        fdata[f][f'hb_HE_{i}_dist'] = str(round(cmd.get_distance(sel_arg, sel_other, state=1),2))
                    else: 
                        fdata[f][f'hb_HE_{i}_fg'] = 'none'

                    HH11_hb = [p for p in hbpairs[i].keys() if f'{arg}/HH11' in p[0] or f'{arg}/HH11' in p[1]]
                    if HH11_hb:
                        other_atom = [at for at in HH11_hb[0] if ligid not in at or 'HH11' not in at][0]
                        oa_chain, oa_resi, oa_name = other_atom.split('/')
                        
                        sel_arg = f"first (model {i} and chain {arg_chain} and resi {arg_resi} and name HH11)"
                        sel_other = f"first (model {i} and chain {oa_chain} and resi {oa_resi} and name {oa_name})"
                        
                        fdata[f][f'hb_HH11_{i}_fg'] = other_atom
                        fdata[f][f'hb_HH11_{i}_dist'] = str(round(cmd.get_distance(sel_arg, sel_other, state=1),2))
                    else: 
                        fdata[f][f'hb_HH11_{i}_fg'] = 'none'

                    HH12_hb = [p for p in hbpairs[i].keys() if f'{arg}/HH12' in p[0] or f'{arg}/HH12' in p[1]]
                    if HH12_hb:
                        other_atom = [at for at in HH12_hb[0] if ligid not in at or 'HH12' not in at][0]
                        oa_chain, oa_resi, oa_name = other_atom.split('/')
                        
                        sel_arg = f"first (model {i} and chain {arg_chain} and resi {arg_resi} and name HH12)"
                        sel_other = f"first (model {i} and chain {oa_chain} and resi {oa_resi} and name {oa_name})"
                        
                        fdata[f][f'hb_HH12_{i}_fg'] = other_atom
                        fdata[f][f'hb_HH12_{i}_dist'] = str(round(cmd.get_distance(sel_arg, sel_other, state=1),2))
                    else: 
                        fdata[f][f'hb_HH12_{i}_fg'] = 'none'

                    HH21_hb = [p for p in hbpairs[i].keys() if f'{arg}/HH21' in p[0] or f'{arg}/HH21' in p[1]]
                    if HH21_hb:
                        other_atom = [at for at in HH21_hb[0] if ligid not in at or 'HH21' not in at][0]
                        oa_chain, oa_resi, oa_name = other_atom.split('/')
                        
                        sel_arg = f"first (model {i} and chain {arg_chain} and resi {arg_resi} and name HH21)"
                        sel_other = f"first (model {i} and chain {oa_chain} and resi {oa_resi} and name {oa_name})"
                        
                        fdata[f][f'hb_HH21_{i}_fg'] = other_atom
                        fdata[f][f'hb_HH21_{i}_dist'] = str(round(cmd.get_distance(sel_arg, sel_other, state=1),2))
                    else: 
                        fdata[f][f'hb_HH21_{i}_fg'] = 'none'

                    HH22_hb = [p for p in hbpairs[i].keys() if f'{arg}/HH22' in p[0] or f'{arg}/HH22' in p[1]]
                    if HH22_hb:
                        other_atom = [at for at in HH22_hb[0] if ligid not in at or 'HH22' not in at][0]
                        oa_chain, oa_resi, oa_name = other_atom.split('/')
                        
                        sel_arg = f"first (model {i} and chain {arg_chain} and resi {arg_resi} and name HH22)"
                        sel_other = f"first (model {i} and chain {oa_chain} and resi {oa_resi} and name {oa_name})"
                        
                        fdata[f][f'hb_HH22_{i}_fg'] = other_atom
                        fdata[f][f'hb_HH22_{i}_dist'] = str(round(cmd.get_distance(sel_arg, sel_other, state=1),2))
                    else: 
                        fdata[f][f'hb_HH22_{i}_fg'] = 'none'
            
            ##########################################################################################

            # delete all pymol objects for this model so nothing left to potentially interfere with next iteration
            for obj in [n for n in cmd.get_names("all") if 'f00001' not in n]: cmd.delete(obj)

            ### collect and process energies ###
            out = subprocess.run(['extract-orca.sh'],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
            extracted = [l for l in out.stdout.split('\n') if l]    # clean up output
            # failsafe to avoid miscalculating deltaG with previous iteration's vals if anything goes wrong with extraction
            Gts = False
            Gr = False
            Gp = False
            Ginit = False
            for line in extracted:
                line = line.split()
                dirsplit = [d for d in line[0].split('/') if d]
                gkcal = float(line[5])*627.5096
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
                fdata[f]['dGa'] = str(round(Gts - Gr,2))
                fdata[f]['dGr'] = str(round(Gp - Gr,2))
                fdata[f]['done'] = 'Y'
            else:
                errorlog.append(f'{f} - extract-orca.sh output not parsed as expected, please check outputs!')
            if Gr:
                os.chdir('..')
                out = subprocess.run(['extract-orca.sh orca.out'],shell=True,stdout=PIPE,stderr=STDOUT,universal_newlines=True)
                extracted = [l for l in out.stdout.split('\n') if l]
                extracted = extracted[0].split()
                fdata[f]['init_elE'] = extracted[1]
                diff_Ha = float(fdata[f]['r_elE']) - float(fdata[f]['init_elE'])
                fdata[f]['dE_r-init'] = str(round(diff_Ha*627.5096,2))
                
        os.chdir(homedir)

    ### make results csv ###
    # note that all values in df here are strings to avoid weird mismatched data types in incomplete columns
    # don't waste time messing with numerical data types to make df directly useable for plotting. save as csv, then more sensible data types will be set automatically when loading from csv :D
    df = pd.DataFrame.from_dict(fdata,orient='index')
    df.to_csv(f'{dirlabel}_results.csv',index_label='frame')

    ### make FG csv ###
    df2 = pd.DataFrame.from_dict(modelFGs,orient='index')
    df2 = df2.fillna(0).astype(int)
    df2.to_csv(f'{dirlabel}_model_FGs.csv',index_label='frame')

    ### make error log file if any errors ###
    if errorlog:
        with open(f'{dirlabel}_collection_errors.txt','w') as fp:
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
    parser.add_argument('-filtbatch',action='store_true',help='label collected results as being from filtered batch models instead of individual')
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
    elif args.filtbatch:
        modeltype = 'filtbatch'
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
