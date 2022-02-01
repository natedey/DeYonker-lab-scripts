#! /usr/bin/env python
import os, sys, glob
import argparse, time, re
from collections import defaultdict

parser = argparse.ArgumentParser(description='Analyzes MD snapshots of Arpeggio SIFT results to generate a Dynamic RIN')
parser.add_argument('-sift', help='.csv file containing SIFT to be analyzed')
parser.add_argument('-noprox', action='store_true', help='If flag present, ignore proximal interactions')
parser.add_argument('-save', default='MDarpeggioFGwatnetwork.csv', help='name of savefile')
args = parser.parse_args()

starttime = time.time()

#Grab water info from header line
seedinter = defaultdict(list)
info = defaultdict(int)

with open(args.sift, "r") as f:

    header = f.readline().strip()
    for count,ele in enumerate(header.split(",")[1:],1):
        if args.noprox == True and ele.split(".")[2] == "Proximal": continue # Possibly ignore Proximal interactions
        if re.findall("[a-zA-Z]+", ele.split(".")[1])[0] != "W": continue # Ignore non-water interactions
        seedinter[ele.split(".")[0]+"-"+ele.split(".")[2]].append(count)

    savefile = open(args.save, "w")
    savefile.write("Frame,"+",".join(seedinter.keys())+"\n")
    for line in f:
        sp = [int(x) for x in line.split(",")]
        s = [sp[0]]
        for inter in seedinter.keys():
            s.append(sum([sp[x] for x in seedinter[inter]]))
        savefile.write(",".join([str(x) for x in s])+"\n")
    savefile.close()


print("Time completed:", (time.time()-starttime))
