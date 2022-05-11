#!/usr/bin/env python

import os, sys

if len(sys.argv) != 6:
    print "#Usage: script.py ProbeData.csv ISAPT-Data.csv FSAPT-Data.csv Distance-Data.csv Compiled-Data-Outputname.csv"
    sys.exit()

probelines = open(sys.argv[1],"r").readlines()
isaptlines = open(sys.argv[2],"r").readlines()
fsaptlines = open(sys.argv[3],"r").readlines()

dataprobe = []
datasapt = []

#Extract Probe Data
#Format: Name,Num1,ID1,Atom1,Type1,Func1,Num2,ID2,Atom2,Type2,Func2,WCcount,CCcount,SOcount,HBcount,BOcount,Score
for item in range(1,len(probelines)):
    if len(probelines[item].split(",")) == 17:
        splitline = probelines[item].split(",")
        splitline[-1] = splitline[-1].strip()
        dataprobe.append(splitline)
    else:
        print "Formatting Error when attempting to extract Probe Data. Check line " + item + "\n" + probelines[item]
        sys.exit()

#Extract ISAPT Data
#Format: Directory,Filename,Res1,Res1Type,Res2,Res2Type,Elst,Exch,IndAB,IndBA,Ind,Disp,Total
for item in range(1,len(isaptlines)):
    if len(isaptlines[item].split(",")) == 13:
        splitline = isaptlines[item].split(",")
        splitline[-1] = splitline[-1].strip()
        splitline.append("ISAPT")
        datasapt.append(splitline)
    else:
        print "Formatting Error when attempting to extract ISAPT Data. Check line " + item + "\n" + isaptlines[item]

#Extract FSAPT Data
#Format: Directory,Filename,Res1,Res1Type,Res2,Res2Type,Elst,Exch,IndAB,IndBA,Ind,Disp,Total
for item in range(1,len(fsaptlines)):
    if len(fsaptlines[item].split(",")) == 13:
        splitline = fsaptlines[item].split(",")
        splitline[-1] = splitline[-1].strip()
        splitline.append("FSAPT")
        datasapt.append(splitline)
    else:
        print "Formatting Error when attempting to extract FSAPT Data. Check line " + item + "\n" + fsaptlines[item]

#Correct Probe Data information on Residues that are interacting
for item in dataprobe:
    if item[4]=="MC":
        item[2] = "MC"
    if item[9]=="MC":
        item[7] = "MC"

#Append Distance Data to Probe Data
distlines = open(sys.argv[4],"r").readlines()
for item in dataprobe:
    for distance in distlines:
        if item[0]==distance.split(",")[0]:
            item.append(distance.split(",")[1].strip())

#Append Interaction Type Data to Probe Data
residuetype = {
        "GLY":"ALI", "ALA":"ALI", "VAL":"ALI", "LEU":"ALI", "ILE":"ALI", "PRO":"ALI",
        "PHE":"ARO", "TYR":"ARO", "TRP":"ARO",
        "SER":"POL", "THR":"POL", "CYS":"POL", "MET":"POL", "ASN":"POL", "GLN":"POL",
        "GLU":"NEG", "ASP":"NEG",
        "ARG":"POS", "LYS":"POS",
        "HIS":"ARO"
}
for item in dataprobe:
    if item[4] == "MC" and item[9] == "MC":
        item.append("MC-MC")
    elif item[4] == "MC" and item[9] != "MC":
        name = "MC-" + residuetype[item[7]]
        item.append(name)
    elif item[4] != "MC" and item[9] == "MC":
        name = "MC-" + residuetype[item[2]]
        item.append(name)
    elif item[4] != "MC" and item[9] != "MC":
        namelist = [residuetype[item[2]], residuetype[item[7]]]
        namelist.sort()
        name = namelist[0] + "-" + namelist[1]
        item.append(name)

#Append Charge Data to Probe Data
residuecharge = {
        "GLY":"NEU", "ALA":"NEU", "VAL":"NEU", "LEU":"NEU", "ILE":"NEU", "PRO":"NEU",
        "PHE":"NEU", "TYR":"NEU", "TRP":"NEU",
        "SER":"NEU", "THR":"NEU", "CYS":"NEU", "MET":"NEU", "ASN":"NEU", "GLN":"NEU",
        "GLU":"NEG", "ASP":"NEG",
        "ARG":"POS", "LYS":"POS",
        "HIS":"NEU"
}
for item in dataprobe:
    if item[4] == "MC" and item[9] == "MC":
        item.append("MC-MC")
    elif item[4] == "MC" and item[9] != "MC":
        name = "MC-" + residuecharge[item[7]]
        item.append(name)
    elif item[4] != "MC" and item[9] == "MC":
        name = "MC-" + residuecharge[item[2]]
        item.append(name)
    elif item[4] != "MC" and item[9] != "MC":
        namelist = [residuecharge[item[2]], residuecharge[item[7]]]
        namelist.sort()
        name = namelist[0] + "-" + namelist[1]
        item.append(name)

#Append Difference Between Sequential Position
for item in dataprobe:
    diff = int(item[10]) - int(item[5])
    item.append(str(diff))

#Compile Probe and SAPT Data
datacompiled = []
#                    p[0] p[5] p[4]  p[2]  p[10] p[9] p[7]   s[13]   s[6] s[7] s[8]  s[9] s[10]s[11]s[12]  p[11]   p[12]   p[13]   p[14]  p[16]   s[0]     p[17]   p[18]   p[19]     p[20]   p[15]
datacompiled.append("Name,Pos1,Type1,Func1,Pos2,Type2,Func2,CalcType,Elst,Exch,IndAB,IndBA,Ind,Disp,Total,WCcount,CCcount,SOcount,HBcount,Score,Directory,CoMDist,IntType,IntCharge,SeqDist,BOcount")

for s in datasapt:
    probepresent = False
    for p in dataprobe:
        if s[1]==p[0]:
            datacompiled.append(p[0] + "," + p[5] + "," +  p[4] + "," + p[2] + "," + p[10] + "," + p[9] + "," + p[7] + "," + s[13] + "," + s[6] + "," + s[7] + "," + s[8] + "," + s[9] + "," + s[10] +\
                    "," + s[11] + "," + s[12] + "," + p[11] + "," + p[12] + "," + p[13] + "," + p[14] + "," + p[16] + "," + s[0] + "," + p[17] + "," + p[18] + "," + p[19] + "," + p[20] + "," + p[15])
            probepresent = True
    if probepresent == False:
        print "Error encountered in retrieving SAPT data for point: " + s

#Write CSV file of compiled data
savefile = open(sys.argv[5],"w")
for item in datacompiled:
    savefile.write("%s\n"%item)
savefile.close()


