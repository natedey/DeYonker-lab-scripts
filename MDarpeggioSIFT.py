#! /usr/bin/env python
import os, sys
import argparse, re, time, statistics
from collections import defaultdict

parser = argparse.ArgumentParser(description='Analyzes MD snapshots of Arpeggio into a SIFT')
parser.add_argument('-data', help='Arpeggio MD data file to be analyzed -- result of MDarpeggio.py')
parser.add_argument('-binary', action='store_true', help='If flag present, use binary instead of contact count')
parser.add_argument('-noprox', action='store_true', help='If flag present, no proximal interactions included')
parser.add_argument('-save', default='MDarpeggioSIFT', help='name of prefix for csv SIFT file.')
args = parser.parse_args()

starttime = time.time()

master = []

#Read data file

tempfile = open("temp.csv","w")
with open(args.data) as readfile:
    for frame in readfile:
        e = defaultdict(int)
        inters = frame.split("|")[1:]
        for inter in inters:

            seed = inter.split(",")[0]
            res = inter.split(",")[1]
            types = [int(x) for x in inter.split(",")[2:]]

            if args.binary==True:
                types = [0 if x==0 else 1 for x in types]

            #Generate incomplete Interaction SIFT
            if types[0] != 0:
                e[seed+"."+res+".Clash"] = types[0]
            if types[1] != 0:
                e[seed+"."+res+".Covalent"] = types[1]
            if types[2] != 0:
                e[seed+"."+res+".VdWClash"] = types[2]
            if types[3] != 0:
                e[seed+"."+res+".VdW"] = types[3]
            if args.noprox==False and types[4] != 0:
                e[seed+"."+res+".Proximal"] =1
            if types[5] != 0:
                e[seed+"."+res+".HBonding"] = types[5]
            if types[6] != 0:
                e[seed+"."+res+".weakHBonding"] = types[6]
            if types[7] != 0:
                e[seed+"."+res+".Halogen"] = types[7]
            if types[8] != 0:
                e[seed+"."+res+".Ionic"] = types[8]
            if types[9] != 0:
                e[seed+"."+res+".Metal"] = types[9]
            if types[10] != 0:
                e[seed+"."+res+".Aromatic"] = types[10]
            if types[11] != 0:
                e[seed+"."+res+".Hydrophobic"] = types[11]
            if types[12] != 0:
                e[seed+"."+res+".Carbonyl"] = types[12]
            if types[13] != 0:
                e[seed+"."+res+".Polar"] = types[13]
            if types[14] != 0:
                e[seed+"."+res+".weakPolar"] = types[14]
        tempfile.write(frame.split("|")[0])
        for item in master:
            if item in e.keys():
                tempfile.write(","+str(e[item]))
                del e[item]
            else: tempfile.write(",0")
        for item in e.keys():
            master.append(item)
            tempfile.write(","+str(e[item]))
        tempfile.write("\n")
tempfile.close()

#Complete Interaction SIFT
savefile = open(args.save+".csv", "w")
savefile.write("Frame,"+",".join(master)+"\n")
with open("temp.csv","r") as readfile:
    for line in readfile:
        if len(line.split(",")) == len(master)+1:
            savefile.write(line)
        else:
            diff = ["0"] * ((len(master)+1)-len(line.split(",")))
            newline = [x.strip() for x in line.split(",")] + diff
            savefile.write(",".join(newline)+"\n")
savefile.close()
os.remove("temp.csv")

print("Time completed:", (time.time()-starttime))
