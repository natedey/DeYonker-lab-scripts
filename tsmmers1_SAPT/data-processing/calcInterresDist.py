#!/usr/bin/env python

import os
import sys
import re

#Usage: script.py pdbfile.pdb savefile.csv

if len(sys.argv) != 3:
    print "\nUsage: script.py pdbfile.pdb savefile.csv\n"
    sys.exit(0)

def appendline(line, dataframe):
    element = line[76:79].strip()
    x = float(line[31:39])
    y = float(line[39:47])
    z = float(line[47:55])
    resnum = int(line[22:27])
    position = determinepos(line, resnum)
    
    if len(dataframe)==0:
        dataframe.append([position,[resnum, element, x, y, z]])
    elif any(sublist[0]==position for sublist in dataframe)==True:
        for sublist in dataframe:
            if sublist[0]==position:
                sublist.append([resnum, element, x, y,z])
    elif any(sublist[0]==position for sublist in dataframe)==False:
        dataframe.append([position,[resnum, element, x, y, z]])

def determinepos(line, num):
    atomtype = line[12:17].strip()
    if atomtype == "N" or atomtype == "H":
        return str(int(num-1)) + "-MC"
    elif atomtype == "C" or atomtype == "O":
        return str(num) + "-MC"
    else:
        return str(num) + "-SC"

#Read the protonated PDB information into a list of lists divided by functional group
pdbdata = []
pdblines = open(sys.argv[1],"r").readlines()
for line in pdblines:
    if line[0:4] == "ATOM":
       appendline(line, pdbdata)
    else: continue

#Compute the center of mass coordinates for each Position
atomicmass = {
        "H":1.0078, "C":12.0107, "N":14.0067, "O":15.999, "S":32.065
        }

def centerofmass(data, xyz):
    templist = []
    for value in range(1,len(data)):
        if xyz == "X":
            templist.append([data[value][1], data[value][2]])
        elif xyz == "Y":
            templist.append([data[value][1], data[value][3]])
        elif xyz == "Z":
            templist.append([data[value][1], data[value][4]])
    totalmass = 0
    summass = 0
    for atom in templist:
        summass += (atomicmass[atom[0]] * atom[1])
        totalmass += atomicmass[atom[0]]
    com = summass/totalmass
    return com

comcoords = []
for item in pdbdata:
    posname = item[0]
    comX = centerofmass(item, "X")
    comY = centerofmass(item, "Y")
    comZ = centerofmass(item, "Z")
    
    comcoords.append([posname, comX, comY, comZ])

#Compute the distance between the center of mass for each position
comdist = []
def distance(x1, y1, z1, x2, y2, z2):
    value = (((x1-x2)**2) + ((y1-y2)**2) + ((z1-z2)**2))**0.5
    return round(value, 2)

for pos1 in comcoords:
    for pos2 in comcoords:
        if int(pos1[0].split("-")[0]) >= int(pos2[0].split("-")[0]):
            continue
        else:
            name = pos1[0] + "_" + pos2[0]
            dist = distance(pos1[1], pos1[2], pos1[3], pos2[1], pos2[2], pos2[3])
            comdist.append([name, dist])

#Write results of center of mass distances to a .csv file
savefile = open(sys.argv[2], "w")
for item in comdist:
    savefile.write("%s,%s\n" % (item[0],str(item[1])))
savefile.close()

