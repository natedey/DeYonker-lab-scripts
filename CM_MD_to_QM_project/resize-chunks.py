#!/usr/bin/env python3

import os, glob, shutil

for i in [2,3,4]:
    ### 1-250 ###
    newdir = f'f0{i}001-f0{i}250'
    print(newdir)
    os.mkdir(newdir)
    dirstomove = glob.glob(f'f0{i}001-f0{i}100/f*') + glob.glob(f'f0{i}101-f0{i}200/f*') + [f for f in glob.glob(f'f0{i}201-f0{i}300/f*') if int(f.split('/')[-1][-3:]) <= 250]
    dirstomove.sort()
    for j in dirstomove:
        fname = j.split('/')[-1]
        os.rename(j,f'{newdir}/{fname}')
    shutil.rmtree(f'f0{i}001-f0{i}100')
    shutil.rmtree(f'f0{i}101-f0{i}200')
    ### 251-500 ###
    newdir = f'f0{i}251-f0{i}500'
    print(newdir)
    os.mkdir(newdir)
    dirstomove = [f for f in glob.glob(f'f0{i}201-f0{i}300/f*') if int(f.split('/')[-1][-3:]) > 250] + glob.glob(f'f0{i}301-f0{i}400/f*') + glob.glob(f'f0{i}401-f0{i}500/f*')
    dirstomove.sort()
    for j in dirstomove:
        fname = j.split('/')[-1]
        os.rename(j,f'{newdir}/{fname}')
    shutil.rmtree(f'f0{i}201-f0{i}300')
    shutil.rmtree(f'f0{i}301-f0{i}400')
    shutil.rmtree(f'f0{i}401-f0{i}500')
    ### 501-750 ###
    newdir = f'f0{i}501-f0{i}750'
    print(newdir)
    os.mkdir(newdir)
    dirstomove = glob.glob(f'f0{i}501-f0{i}600/f*') + glob.glob(f'f0{i}601-f0{i}700/f*') + [f for f in glob.glob(f'f0{i}701-f0{i}800/f*') if int(f.split('/')[-1][-3:]) <= 750]
    dirstomove.sort()
    for j in dirstomove:
        fname = j.split('/')[-1]
        os.rename(j,f'{newdir}/{fname}')
    shutil.rmtree(f'f0{i}501-f0{i}600')
    shutil.rmtree(f'f0{i}601-f0{i}700')
    ### 751-1000 ###
    newdir = f'f0{i}751-f0{i+1}000'
    print(newdir)
    os.mkdir(newdir)
    dirstomove = [f for f in glob.glob(f'f0{i}701-f0{i}800/f*') if int(f.split('/')[-1][-3:]) > 750] + glob.glob(f'f0{i}801-f0{i}900/f*') + glob.glob(f'f0{i}901-f0{i+1}000/f*')
    dirstomove.sort()
    for j in dirstomove:
        fname = j.split('/')[-1]
        os.rename(j,f'{newdir}/{fname}')
    shutil.rmtree(f'f0{i}701-f0{i}800')
    shutil.rmtree(f'f0{i}801-f0{i}900')
    shutil.rmtree(f'f0{i}901-f0{i+1}000')

print('new rearranged dirs do not have check_initialopt_[status].txt lists! you\'ll need to run check_cm_jobs in them again before starting new jobs')
