#!/usr/bin/env python

import os
import sys
import re

#Usage: ProbeToFG.py probefile

if (len(sys.argv) < 2 or len(sys.argv) > 2):
    print "\nUsage: ProbeToFG.py probefile\n"
    sys.exit(0)

#Format of probe unformatted output: name:pat:type:srcAtom:targAtom:dot-count:mingap:gap:spX:spY:spZ:spikeLen:score:stype:ttype:x:y:z:sBval:tBval:

atomtoelement = {
    "C":"C","C1":"C","C10":"C","C11":"C","C12":"C","C13":"C","C8":"C","C9":"C","CA":"C","CB":"C",
	"CD":"C","CD1":"C","CD2":"C","CE":"C","CE1":"C","CE2":"C","CE3":"C","CG":"C","CG1":"C","CG2":"C",
	"CH":"C","CH1":"C","CH2":"C","CZ":"C","CZ1":"C","CZ2":"C","CZ3":"C",
        "H":"H","H?":"H","H1":"H","H10":"H","H11":"H","H12":"H","H13":"H","H2":"H","H3":"H","H8":"H",
	"HA":"H","HA2":"H","HA3":"H","HB":"H","HB1":"H","HB2":"H","HB3":"H","HD":"H","HD1":"H","HD11":"H",
	"HD12":"H","HD13":"H","HD2":"H","HD21":"H","HD22":"H","HD23":"H","HD3":"H","HE":"H","HE1":"H",
	"HE2":"H","HE21":"H","HE22":"H","HE3":"H","HG":"H","HG1":"H","HG11":"H","HG12":"H","HG13":"H","HG2":"H",
	"HG21":"H","HG22":"H","HG23":"H","HG3":"H","HH":"H","HH1":"H","HH11":"H","HH12":"H","HH2":"H","HH21":"H",
	"HH22":"H","HZ":"H","HZ1":"H","HZ2":"H","HZ3":"H",
        "N":"N","ND":"N","ND1":"N","ND2":"N","NE":"N","NE1":"N","NE2":"N","NH":"N","NH1":"N","NH2":"N","NZ":"N",
        "O":"O","OD":"O","OD1":"O","OD2":"O","OE":"O","OE1":"O","OE2":"O","OG":"O","OG1":"O","OH":"O",
        "S":"S","SD":"S","SG":"S"
}

atomchain = {
    "C":"MC","C1":"SC","C10":"SC","C11":"SC","C12":"SC","C13":"SC","C8":"SC","C9":"SC","CA":"SC","CB":"SC",
	"CD":"SC","CD1":"SC","CD2":"SC","CE":"SC","CE1":"SC","CE2":"SC","CE3":"SC","CG":"SC","CG1":"SC","CG2":"SC",
	"CH":"SC","CH1":"SC","CH2":"SC","CZ":"SC","CZ1":"SC","CZ2":"SC","CZ3":"SC",
        "H":"MC","H?":"SC","H1":"SC","H10":"SC","H11":"SC","H12":"SC","H13":"SC","H2":"SC","H3":"SC","H8":"SC",
	"HA":"SC","HA2":"SC","HA3":"SC","HB":"SC","HB1":"SC","HB2":"SC","HB3":"SC","HD":"SC","HD1":"SC","HD11":"SC",
	"HD12":"SC","HD13":"SC","HD2":"SC","HD21":"SC","HD22":"SC","HD23":"SC","HD3":"SC","HE":"SC","HE1":"SC",
	"HE2":"SC","HE21":"SC","HE22":"SC","HE3":"SC","HG":"SC","HG1":"SC","HG11":"SC","HG12":"SC","HG13":"SC","HG2":"SC",
	"HG21":"SC","HG22":"SC","HG23":"SC","HG3":"SC","HH":"SC","HH1":"SC","HH11":"SC","HH12":"SC","HH2":"SC","HH21":"SC",
	"HH22":"SC","HZ":"SC","HZ1":"SC","HZ2":"SC","HZ3":"SC",
        "N":"MC","ND":"SC","ND1":"SC","ND2":"SC","NE":"SC","NE1":"SC","NE2":"SC","NH":"SC","NH1":"SC","NH2":"SC","NZ":"SC",
        "O":"MC","OD":"SC","OD1":"SC","OD2":"SC","OE":"SC","OE1":"SC","OE2":"SC","OG":"SC","OG1":"SC","OH":"SC","OXT":"MC",
        "S":"SC","SD":"SC","SG":"SC"
}


probefilename = sys.argv[1]
probedata = [["Name","Num1","ID1","Atom1","Type1","Func1","Num2","ID2","Atom2","Type2","Func2","WCcount","CCcount","SOcount","HBcount","BOcount","Score"]]

print("Running program on probefile: " + probefilename + "\n")
firstres = 100
lastres = 0
listresid = []
with open(probefilename) as probefile:
    print("Identifying terminal residue identities\n")
    for line in probefile:
        lastres = int(line[12:16]) if int(line[12:16]) > lastres else lastres
        lastres = int(line[29:32]) if int(line[29:32]) > lastres else lastres
        firstres = int(line[12:16]) if int(line[12:16]) < firstres else firstres
        firstres = int(line[29:32]) if int(line[29:32]) < firstres else firstres
        if [int(line[12:16]), line[16:20].strip()] not in listresid:
            listresid.append([int(line[12:16]), line[16:20].strip()])
listresid.sort()

print("Re-categorizing probe interactions into terms of Chemical Functional Units\n")
with open(probefilename) as probefile:
    for line in probefile:
        contacttype = line[6:8]
        res1num = int(line[12:16])
        res1id = line[16:19].strip()
        res1atom = line[20:24].strip()
        res2num = int(line[29:32])
        res2id = line[33:36].strip()
        res2atom = line[37:41].strip()
        
        coordstring = line[43:]
        coordsplit = coordstring.split(":")
        score  = float(coordsplit[6])
        
        probool = False

        #Assign generic interaction names
        res1type = atomchain[res1atom]
        res2type = atomchain[res2atom]
        if (res1type == "MC" and res2type == "MC"):
            interaction = "MC-MC"
        elif (res1type == "SC" and res2type == "SC"):
            interaction = "SC-SC"
        else:
            interaction = "MC-SC"

        #Reassign MC Functional Group Positions
        res1func = res1num
        res2func = res2num
        if res1type == "MC":
            if res1atom == "N" or res1atom == "H":
                res1func -= 1
        if res2type == "MC":
            if res2atom == "N" or res2atom == "H":
                res2func -= 1

        #Skip interactions between immediately adjacent functional groups
        if (interaction == "MC-SC" and abs(res1func - res2func) == 0):
            continue
        if (interaction == "MC-SC" and res1type == "MC" and (res2func - res1func) == 1):
            continue
        if (interaction == "MC-SC" and res2type == "MC" and (res1func - res2func) == 1):
            continue
        #Skip same functional group interactions
        if (res1func == res2func):
            continue

        #Skip interactions with the terminal functional groups
        if res1func == 0 or res2func == 0 or res1func == (firstres-1) or res2func == (firstres-1):
            continue
        if (res1func == firstres and res1type == "SC") or (res2func == firstres and res2type == "SC"):
            continue
        if(res1func == lastres) or (res2func == lastres):
            continue

        #Name interaction pairs
        if res1func < res2func:
            name = str(res1func) + "-" + res1type + "_" + str(res2func) + "-" + res2type
        elif res2func < res1func:
            res1num, res2num = res2num, res1num
            res1id, res2id = res2id, res1id
            res1atom, res2atom = res2atom, res1atom
            res1type, res2type = res2type, res1type
            res1func, res2func = res2func, res1func
            name = str(res1func) + "-" + res1type + "_" + str(res2func) + "-" + res2type

        #Skip interaction pairs with PRO that will make ISAPT calculations
        if (res1type == res2type == "SC" and res1id == "PRO") or (res1type == res2type == "SC" and res2id == "PRO"):
            if abs(res1func-res2func)<=2: probool = True
        if (res1type == "SC" and res1id == "PRO" and res2type == "MC"):
            if abs(res1func-res2func)<=1: probool = True
        if (res2type == "SC" and res2id == "PRO" and res1type == "MC"):
            if abs(res1func-res2func)<=3: probool = True
        if (res1type == res2type == "MC" and (res2func-res1func)<=3):
            for i in listresid:
                if (res1func+1) in i and "PRO" in i:
                    probool = True
                if (res2func+1) in i and "PRO" in i:
                    probool = True
        if (res1type == "MC" and res2type == "SC" and (res2func-res1func)<=3):
            for i in listresid:
                if res1func+1 in i and "PRO" in i:
                    probool = True
        if (res2type == "MC" and res1type == "SC" and (res2func-res1func)<=2):
            for i in listresid:
                if res2func+1 in i and "PRO" in i:
                    probool = True

        if probool == True:
            continue

        #Generate list of lists
        #Format: Name Num1 ID1 Atom1 Type1 Func1 Num2 ID2 Atom2 Type2 Func2 WCcount CCcount SOcount HBcount Score
        for sublist in probedata:
            if sublist[0] == name:
                if contacttype == "wc":
                    sublist[11] +=1
                if contacttype == "cc":
                    sublist[12] +=1
                if contacttype == "so":
                    sublist[13] += 1
                if contacttype == "hb":
                    sublist[14] +=1
                if contacttype == "bo":
                    sublist[15] +=1
                sublist[16] += score
        if (any(name in x for x in probedata)) == False:
            wccount = cccount = socount = hbcount = bocount =0
            if contacttype == "wc":
                wccount +=1
            elif contacttype == "cc":
                cccount +=1
            elif contacttype == "so":
                socount +=1
            elif contacttype == "hb":
                hbcount +=1
            elif contacttype == "bo":
                bocount +=1
            probedata.append([name, res1num, res1id, res1atom, res1type, res1func, res2num, res2id, res2atom, res2type, res2func,
                wccount, cccount, socount, hbcount, bocount, score])

writefilename = sys.argv[1].split(".")[0] + "_probedata.csv"
siffilename = sys.argv[1].split(".")[0] + "_sifdata.sif"

print("Writing CSV-formatted probe data: " + writefilename)
writefile = open(writefilename, "w")
for item in probedata:
    writefile.write(",".join(map(str,item)))
    writefile.write("\n")
writefile.close()

print("Writing SIF-formatted interaction data: " + siffilename)
siffile = open(siffilename, "w")
for item in probedata:
    node1 = item[4] + "-" + str(item[5])
    inter = item[4] + "-" + item[9]
    node2 = item[9] + "-" + str(item[10])
    siffile.write(node1 + "\t" + inter + "\t" + node2 + "\n")
siffile.close()
