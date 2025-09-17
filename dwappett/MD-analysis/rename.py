#!/usr/bin/env python3

import os
import sys
import glob

r = sys.argv[1]

fnum = [0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000, 11000, 12000, 13000, 14000, 15000, 16000, 17000, 18000, 19000, 20000]
flab = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t']

pdbs = glob.glob(f'{r}/run{r}.*.pdb')
for p in pdbs:
    frame = p.split('.')[1].zfill(5)
    for i in range(len(fnum)):
        if int(frame) > fnum[i] and int(frame) <= fnum[i+1]:
            #print(f'{frame} : {flab[i]} (between {fnum[i]} and {fnum[i+1]})')
            os.renames(p,f'{r}{flab[i]}/run{r}.{frame}.pdb')
            break

