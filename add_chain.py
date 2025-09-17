import os, sys, argparse
from collections import defaultdict

parser = argparse.ArgumentParser(description='Add chain info to PDBs named in list file')
parser.add_argument('-list', dest='listfile', help='list MD simulation PDBs')
parser.add_argument('-chain', nargs = '+', help='default chain is W. Alt format: startres/endres/chainletter e.g. 1/123/A 124/130/B 131/131/C')
args = parser.parse_args()

pdbnames = open(args.listfile, 'r').readlines()
pdbnames = [x.strip() for x in pdbnames]

#Create dictionary of residues and their chains
reschain = {}
for item in args.chain:
    firstres = int(item.split("/")[0])
    lastres = int(item.split("/")[1])
    chainid = item.split("/")[2]
    for i in range(firstres, lastres+1): 
        reschain[i] = chainid

for name in pdbnames:
    watID = defaultdict(list)
    orig = open(name, "r").readlines()
    new = open(name, "w")
    for line in orig:
        if line[0:3]=="END": new.write(line)
        elif int(line[22:26]) in reschain.keys() and line[17:20] != "WAT":
            temp = list(line)
            temp[21] = reschain[int(line[22:26])]
            temp = "".join(temp)
            new.write(temp)
        elif line[17:20] == "WAT":
            if int(line[22:26]) in watID.keys() and line[13:15] in watID[int(line[22:26])]:
                temp = list(line)
                temp[21] = "Z"
                temp = "".join(temp)
                new.write(temp)
            else:
                watID[int(line[22:26])].append(line[13:15])
                temp = list(line)
                temp[21] = "W"
                temp = "".join(temp)
                new.write(temp)
        else:
            temp = list(line)
            temp[21] = "W"
            temp = "".join(temp)
            new.write(temp)
    new.close()

