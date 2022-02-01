#! /usr/bin/env python
import os, sys
import argparse, re
from collections import defaultdict

parser = argparse.ArgumentParser(description='Analyzes MD Arpeggio snapshots to examine maximal models')
parser.add_argument('-dat', help='snapshot .dat file to be analyzed')
parser.add_argument('-noprox', action='store_true', help='flag to exclude proximal-only interactions')
parser.add_argument('-nowat', action='store_false', help='flag to exclude waters from analysis')
parser.add_argument('-save', default='MDarpeggioMax.csv', help='name of savefile')
args = parser.parse_args()

maxmod = defaultdict(list)

with open(args.dat, "r") as readfile:
    for line in readfile:
        watcount = 0
        res = set()
        index = int(line.split("|")[0])
        for i in line.split("|")[1:]:
            if sum(int(j) for j in i.split(",")[2:6]+i.split(",")[7:]) == 0 and args.noprox == True: continue

            if re.sub(r'[0-9]', '', i.split(",")[1]) == "W": watcount +=1
#            else: res.add(i.split(",")[1])
            else: res.add(i.split(",")[1].split("-")[0])
        if args.nowat == True: res.add("W"+str(watcount))
        res = list(res)
        res.sort()
        maxmod[frozenset(res)].extend([index])
        
savefile = open(args.save, "w")
savefile.write("Size,Reslist,Frames\n")
for model in maxmod.keys():
    m = list(model)
    m.sort()
        
    l = str(len(m))

    i = maxmod[model]
    i.sort()

    savefile.write(l+","+"|".join(m)+","+"|".join(list(map(str,i)))+"\n")
savefile.close()
