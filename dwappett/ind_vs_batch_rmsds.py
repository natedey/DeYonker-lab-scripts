#!/home/dwappett/miniconda3/envs/pymol/bin/python3

import os, os.path
import glob
from pymol import cmd
import pandas as pd
from model_details import *
from check_residue_atom import *


i_paths = {'A:128': '/project/ndyonker/chem/cm-MD-processing/MD-QM/QM-A',
            'B:256': '/project/pssntngr/chem/chorismate_mutase/QM-B',
            'C:384': '/project/hksasi/chem/chorismate_mutase/QM-C'}
i2_paths = {'A:128': '/project/dwappett/chorismate_mutase/QM-ind-models-every-100th/A128-f05100-f20000',
            'B:256': '/project/dwappett/chorismate_mutase/QM-ind-models-every-100th/B256-f05100-f20000',
            'C:384': '/project/dwappett/chorismate_mutase/QM-ind-models-every-100th/C384-f05100-f20000'}


b_paths = {'A:128': '/project/dwappett/chorismate_mutase/QM-batch-models/A128-every-100th',
            'B:256': '/project/dwappett/chorismate_mutase/QM-batch-models/B256-every-100th',
            'C:384': '/project/dwappett/chorismate_mutase/QM-batch-models/C384-every-100th'}

fb_paths = {'A:128': '/project/dwappett/chorismate_mutase/QM-batch-models/A128-every-100th-1pct-filter',
            'B:256': '/project/dwappett/chorismate_mutase/QM-batch-models/B256-every-100th-1pct-filter',
            'C:384': '/project/dwappett/chorismate_mutase/QM-batch-models/C384-every-100th-1pct-filter'}


framelist = ['f'+str(i).zfill(5) for i in range(100,20001,100)]

#rmsdnames = [f'rms_{i}_{j}_{k}' for i in ['i-b','b-fb','i-fb'] for j in ['r','ts','p'] for k in ['all','lig','prot','wat']]
rmsdnames = [(i,j,k,l) for i in ['i-b','b-fb','i-fb'] for j in ['r','ts','p'] for k in framelist for l in ['A:128','B:256','C:384']]

rmsds = {i: {} for i in rmsdnames}

for frame in framelist:
    print(frame)
    for lig in ['A:128','B:256','C:384']:
        sel_key = get_sel_keys(lig)
        strucs = {}
        if glob.glob(f'{i_paths[lig]}/*/{frame}/tsopt/*-ts-opt.pdb'):
            strucs['i_ts'] = glob.glob(f'{i_paths[lig]}/*/{frame}/tsopt/*-ts-opt.pdb')
        else:
            strucs['i_ts'] = glob.glob(f'{i2_paths[lig]}/{frame}/tsopt/*-ts-opt.pdb')
        if glob.glob(f'{i_paths[lig]}/*/{frame}/tsopt/irc*/*-reactant-opt.pdb'):
            strucs['i_r'] = glob.glob(f'{i_paths[lig]}/*/{frame}/tsopt/irc*/*-reactant-opt.pdb')
        else:
            strucs['i_r'] = glob.glob(f'{i2_paths[lig]}/{frame}/tsopt/irc*/*-reactant-opt.pdb')
        if glob.glob(f'{i_paths[lig]}/*/{frame}/tsopt/irc*/*-product-opt.pdb'):
            strucs['i_p'] = glob.glob(f'{i_paths[lig]}/*/{frame}/tsopt/irc*/*-product-opt.pdb')
        else:
            strucs['i_p'] = glob.glob(f'{i2_paths[lig]}/{frame}/tsopt/irc*/*-product-opt.pdb')
        #strucs['i_ts'] = glob.glob(f'{i_paths[lig]}/*/{frame}/tsopt/*-ts-opt.pdb') + glob.glob(f'{i2_paths[lig]}/{frame}/tsopt/*-ts-opt.pdb')
        #strucs['i_r'] = glob.glob(f'{i_paths[lig]}/*/{frame}/tsopt/irc*/*-reactant-opt.pdb') + glob.glob(f'{i2_paths[lig]}/{frame}/tsopt/irc*/*-reactant-opt.pdb')
        #strucs['i_p'] = glob.glob(f'{i_paths[lig]}/*/{frame}/tsopt/irc*/*-product-opt.pdb') + glob.glob(f'{i2_paths[lig]}/{frame}/tsopt/irc*/*-product-opt.pdb')
        strucs['b_ts'] = glob.glob(f'{b_paths[lig]}/{frame}/tsopt/*-ts-opt.pdb')
        strucs['b_r'] = glob.glob(f'{b_paths[lig]}/{frame}/tsopt/irc*/*-reactant-opt.pdb')
        strucs['b_p'] = glob.glob(f'{b_paths[lig]}/{frame}/tsopt/irc*/*-product-opt.pdb')
        strucs['fb_ts'] = glob.glob(f'{fb_paths[lig]}/{frame}/tsopt/*-ts-opt.pdb')
        strucs['fb_r'] = glob.glob(f'{fb_paths[lig]}/{frame}/tsopt/irc*/*-reactant-opt.pdb')
        strucs['fb_p'] = glob.glob(f'{fb_paths[lig]}/{frame}/tsopt/irc*/*-product-opt.pdb')

        print(f'no. completed strucs with lig {lig}: {len([key for key in strucs.keys() if strucs[key]])}')
        if len([key for key in strucs.keys() if strucs[key]]) == 9:
            for key in strucs.keys():
                strucs[key] = strucs[key][0]
                cmd.load(strucs[key],key)
            for i in ['i-b','b-fb','i-fb']:
                for j in ['r','ts','p']:
                    s1 = f'{i.split("-")[0]}_{j}'
                    s2 = f'{i.split("-")[1]}_{j}'
                    rmsds[(i,j,frame,lig)]['all'] = str(round(cmd.rms_cur(s1,s2),2))
                    rmsds[(i,j,frame,lig)]['lig'] = str(round(cmd.rms_cur(f'{s1} and resn COR',f'{s2} and resn COR'),2))
                    rmsds[(i,j,frame,lig)]['prot'] = str(round(cmd.rms_cur(f'{s1} and not resn COR and not resn WAT',f'{s2} and not resn COR and not resn WAT'),2))
                    rmsds[(i,j,frame,lig)]['wat'] = str(round(cmd.rms_cur(f'{s1} and resn WAT',f'{s2} and resn WAT'),2))
                    # find FGs mutual to both strucs
                    lst1 = get_model_FGs(strucs[s1],sel_key)
                    lst2 = get_model_FGs(strucs[s2],sel_key)
                    FGs = [f for f in lst1 if f in lst2]
                    for f in FGs:
                        fid = f[0].split(':')
                        fname = str(int(fid[1])%128)+'_'+f[1]
                        if f[1].startswith('SC'):
                            if f[1].endswith('GLY'):
                                continue
                            else:
                                sel = f'chain {fid[0]} and resi {fid[1]} and sidechain and not (elem H and bound_to name CA)'
                        elif f[1] == 'MC':
                            sel = f'((chain {fid[0]} and resi {fid[1]} and (name C or name O)) or (chain {fid[0]} and resi {int(fid[1])+1} and (name N or name H)))'
                        else:
                            sel = f'chain {fid[0]} and resi {fid[1]}'
                        rmsds[(i,j,frame,lig)][fname] = str(round(cmd.rms_cur(f'({s1} and {sel})',f'({s2} and {sel})'),2))
        cmd.delete("all")

df = pd.DataFrame.from_dict(rmsds, orient='index')
df.to_csv(f'batch_vs_ind_rmsds.csv',index_label=('comp','struc','frame','ligand'))

# to read into notebook later: df = pd.read_csv('batch_vs_ind_rmsds.csv', index_col=('frame','ligand'))
