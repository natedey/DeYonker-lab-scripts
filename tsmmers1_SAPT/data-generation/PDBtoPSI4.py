#!/usr/bin/env python

import os
import sys

pdbname = sys.argv[-2]
configname = sys.argv[-1]

pdbfile = open(pdbname)
pdblines = pdbfile.readlines()
pdbfile.close()

#Generate savefile name
res1 = int(pdblines[0].split()[4])
res2 = int(pdblines[len(pdblines)-2].split()[4])
res1type = pdblines[0].split()[3]
res2type = pdblines[len(pdblines)-2].split()[3]

savefilename = str(res1) + "_" + str(res2) + ".dat"

#Establish residue charges
res1charge = 0
res2charge = 0

def rescharge(res):
    counter = 0
    for i in range(len(pdblines)-1):
        splitline = pdblines[i].split()
        if int(splitline[4])==res and splitline[10]=="N1+":
            counter+=1
        if int(splitline[4])==res and splitline[10]=="O1-":
            counter-=1
    return counter

res1charge = rescharge(res1)
res2charge = rescharge(res2)

#Print input file header
savefile = open(savefilename,"w")
savefile.write("memory 10GB\n\n")
savefile.write("molecule " + res1type + str(res1) + "_" + res2type + str(res2) + " {\n")

#Write residues to file

def writeres(res):
    for i in range(len(pdblines)-1):
        splitline = pdblines[i].split()
        if int(splitline[4])==res:
            savefile.write(list(splitline[10])[0] + "        " + splitline[5] + "  " + splitline[6] + "  " + splitline[7] + "\n")
    
savefile.write(str(res1charge) + " 1\n")
writeres(res1)

savefile.write("--\n")

savefile.write(str(res2charge) + " 1\n")
writeres(res2)

savefile.write("\n     units angstrom\n")
savefile.write("     no_reorient\n")
savefile.write("     symmetry c1\n}\n\n")

#Append config file code to inputfile
configfile = open(configname, "r")
configdata = configfile.read()
configfile.close()

savefile.write(configdata)

savefile.close()

print("Psi4 inputfile generated for " + str(res1) + "_" + str(res2))
