#! /usr/bin/env python
import os, sys, argparse
from collections import defaultdict
from operator import itemgetter

parser = argparse.ArgumentParser(description='Computes smallest distances from any atom of the seed to any residue')
parser.add_argument('pdb', help='name of pdbfile')
parser.add_argument('-nohydro', action='store_true', help='If flag present, ignore hydrogen atoms from distance calculations')
parser.add_argument('seed', nargs='+', help='seed selection written in format A:1 A:2 B:15 B:16')
parser.add_argument('-save', default='dist.dat', help='name of savefile')
args = parser.parse_args()

seed = defaultdict(list)
res = defaultdict(list)

with open(args.pdb) as pdbfile:
    for line in pdbfile:
        if line.split()[0] == "ATOM" or line.split()[0] == "HETATM":
            if args.nohydro==True and line[77]=="H": continue

            if line[21]+":"+line[22:26].strip() in args.seed:
                seed[line[21]+":"+line[22:26].strip()].append([line[12:16].strip(), float(line[31:38]), float(line[38:46]), float(line[46:54])])
            else:
                res[line[21]+":"+line[22:26].strip()].append([line[12:16].strip(), float(line[31:38]), float(line[38:46]), float(line[46:54])])

dists = []
for item in res.keys():
    subdist = defaultdict(float)
    for atom in res[item]:
        for item2 in seed.keys():
            for atom2 in seed[item2]:
                subdist[atom[0]+":"+item2+":"+atom2[0]] = ( ((atom[1]-atom2[1])**2) + ((atom[2]-atom2[2])**2) + ((atom[3]-atom2[3])**2) )**0.5
    dists.append([item, min(subdist, key=subdist.get), subdist[min(subdist, key=subdist.get)]])

dists = sorted(dists, key=itemgetter(2))

savefile = open(args.save, "w")
savefile.write("Seed info: \t"+" ".join(args.seed)+"\n")
savefile.write("Chain:Res:Atom\tChain:Seed:Atom\tDistance\n")
for item in dists:
    savefile.write(item[0]+":"+item[1].split(":",1)[0]+"\t\t"+item[1].split(":",1)[1]+"\t\t"+str(item[2])+"\n")
savefile.close()
