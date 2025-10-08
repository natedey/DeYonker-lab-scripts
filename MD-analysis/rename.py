#!/usr/bin/env python3
"""
basic script created by Dr. Domi Wappett in July 2025
turns [dir] containing up to 20000 pdbs into [dir]_a, [dir]_b, [dir]_c, ... each containing max 1000 pdbs for easier MD processing
also adds leading zeros to pdb names for easier sorting
"""

import os
import sys
import glob

r = sys.argv[1]

fnum = [0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000, 17000, 18000, 19000, 20000]
flab = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t']

pdbs = glob.glob(f'{r}/*.pdb')
for p in pdbs:
    # get base file name and zero-padded frame number
    pdbf = p.replace(f'{r}/','').rsplit('.',2)[0]
    frame = p.split('.')[-2].zfill(5)
    # check where frame belongs and move pdb (now with padded frame number) to new letter-labelled directory
    for i in range(len(fnum)):
        if int(frame) > fnum[i] and int(frame) <= fnum[i+1]:
            #os.renames(p,f'{r}{flab[i]}/run{r}.{frame}.pdb')
            os.renames(p,f'{r}_{flab[i]}/{pdbf}.{frame}.pdb')
            break

