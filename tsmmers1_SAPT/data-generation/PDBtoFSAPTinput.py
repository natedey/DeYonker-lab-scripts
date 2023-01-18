#!/usr/bin/env python

import os
import sys

#Usage:  pdb_to_gaussian.py pdbname

pdbname = sys.argv[-1]

pdbfile = open(pdbname)
pdblines = pdbfile.readlines()
pdbfile.close()

#Generate savefile name
pdbnamesplit = pdbname.split("H")[0]
res1 = int(pdbnamesplit.split("_")[0].split("-")[0])
res2 = int(pdbnamesplit.split("_")[1].split("-")[0])

res1type = str()
res2type = str()
elements = []
residues = []
for i in range(len(pdblines)-1):
    if int(pdblines[i][23:27]) == res1:
        res1type = pdblines[i][26:27]
    if int(pdblines[i][23:27]) == res2:
        res2type = pdblines[i][26:27]
    if pdblines[i].split()[-1] not in elements:
        elements.extend(pdblines[i].split()[-1])
    if int(pdblines[i][23:27]) not in residues:
        residues.extend([int(pdblines[i][23:27])])
residues.remove(res1)
residues.remove(res2)
savefilename = pdbnamesplit + ".gau"

#Establish residue charges
res1charge = 0
res2charge = 0

def rescharge(res):
    counter = 0
    for i in range(len(pdblines)-1):
        if int(pdblines[i][23:27])==res and pdblines[i].split()[-1]=="N1+":
            counter+=1
        if int(pdblines[i][23:27])==res and pdblines[i].split()[-1]=="O1-":
            counter-=1
    return counter

res1charge = rescharge(res1)
res2charge = rescharge(res2)
totalcharge = res1charge + res2charge

res1inter = pdbnamesplit.split("_")[0].split("-")[1]
res2inter = pdbnamesplit.split("_")[1].split("-")[1]

#Print Gaussian input file header
savefile = open(savefilename,"w")
savefile.write("%nprocshared=5\n")
savefile.write("%mem=10GB\n")
savefile.write("#P b3lyp/gen opt EmpiricalDispersion=GD3BJ scrf(cpcm,read,solvent=water) gfinput scf=(xqc,maxcon=128,maxcyc=128)\n\n")
savefile.write("molecule " + pdbnamesplit + "\n\n")
savefile.write(str(totalcharge) + " 1\n")

fisaptcounter = 1
fisaptlineA1 = []
fisaptlineA2 = []
fisaptlineB1 = []
fisaptlineB2 = []

for i in range(len(pdblines)-1):
    #Write coordinates to Gaussian input file
    if pdblines[i].split()[-1]=="H":
        savefile.write(pdblines[i].split()[-1] + "        " + " 0 \t" + pdblines[i][28:56] + "\n")
    else:
        savefile.write(pdblines[i].split()[-1][:1] + "        " + "-1 \t" + pdblines[i][28:56] + "\n")

    #Determine if atom position needs to be assigned to the FISAPT file for computing FSAPT interaction
    if res1inter=="MC" and res2inter=="MC":
        if int(pdblines[i][23:27])==res1-1 or int(pdblines[i][23:27])==res1+2:
            fisaptlineA2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res1:
            if pdblines[i][13:17].strip() == "C" or pdblines[i][13:17].strip()=="O":
                fisaptlineA1.append(fisaptcounter)
            else:
                fisaptlineA2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res1+1:
            if pdblines[i][13:17].strip() == "N" or pdblines[i][13:17].strip() == "H":
                fisaptlineA1.append(fisaptcounter)
            else:
                fisaptlineA2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res2-1 or int(pdblines[i][23:27])==res2+2:
            fisaptlineB2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res2:
            if pdblines[i][13:17].strip() == "C" or pdblines[i][13:17].strip() == "O":
                fisaptlineB1.append(fisaptcounter)
            else:
                fisaptlineB2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res2+1:
            if pdblines[i][13:17].strip() == "N" or pdblines[i][13:17].strip() == "H":
                fisaptlineB1.append(fisaptcounter)
            else:
                fisaptlineB2.append(fisaptcounter)

    if res1inter=="MC" and res2inter=="SC":
        if int(pdblines[i][23:27])==res1-1 or int(pdblines[i][23:27])==res1+2:
            fisaptlineA2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res1:
            if pdblines[i][13:17].strip() == "C" or pdblines[i][13:17].strip()=="O":
                fisaptlineA1.append(fisaptcounter)
            else:
                fisaptlineA2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res1+1:
            if pdblines[i][13:17].strip() == "N" or pdblines[i][13:17].strip() == "H":
                fisaptlineA1.append(fisaptcounter)
            else:
                fisaptlineA2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res2:
            if pdblines[i][13:17].strip()!="C" and pdblines[i][13:17].strip()!="O" and pdblines[i][13:17].strip()!="N" and pdblines[i][13:17].strip()!="H":
                fisaptlineB1.append(fisaptcounter)
            else:
                fisaptlineB2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res2+1 or int(pdblines[i][23:27])==res2-1:
            fisaptlineB2.append(fisaptcounter)

    if res1inter=="SC" and res2inter=="MC":
        if int(pdblines[i][23:27])==res1:
            if pdblines[i][13:17].strip()!="C" and pdblines[i][13:17].strip()!="O" and pdblines[i][13:17].strip()!="N" and pdblines[i][13:17].strip()!="H":
                fisaptlineA1.append(fisaptcounter)
            else:
                fisaptlineA2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res1+1 or int(pdblines[i][23:27])==res1-1:
            fisaptlineA2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res2-1 or int(pdblines[i][23:27])==res2+2:
            fisaptlineB2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res2:
            if pdblines[i][13:17].strip() == "C" or pdblines[i][13:17].strip() == "O":
                fisaptlineB1.append(fisaptcounter)
            else:
                fisaptlineB2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res2+1:
            if pdblines[i][13:17].strip() == "N" or pdblines[i][13:17].strip() == "H":
                fisaptlineB1.append(fisaptcounter)
            else:
                fisaptlineB2.append(fisaptcounter)

    if res1inter=="SC" and res2inter=="SC":
        if int(pdblines[i][23:27])==res1:
            if pdblines[i][13:17].strip()!="C" and pdblines[i][13:17].strip()!="O" and pdblines[i][13:17].strip()!="N" and pdblines[i][13:17].strip()!="H":
                fisaptlineA1.append(fisaptcounter)
            else:
                fisaptlineA2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res1+1 or int(pdblines[i][23:27])==res1-1:
            fisaptlineA2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res2:
            if pdblines[i][13:17].strip()!="C" and pdblines[i][13:17].strip()!="O" and pdblines[i][13:17].strip()!="N" and pdblines[i][13:17].strip()!="H":
                fisaptlineB1.append(fisaptcounter)
            else:
                fisaptlineB2.append(fisaptcounter)
        elif int(pdblines[i][23:27])==res2+1 or int(pdblines[i][23:27])==res2-1:
            fisaptlineB2.append(fisaptcounter)

    fisaptcounter+=1

#Write Basis Sets to Gaussian Inputfile    
if "S" in elements:
    savefile.write("\nS     0\n6-31G(d')\n****")

savefile.write("\nO     0\n")
savefile.write("6-31G(d')\n")
savefile.write("****\n")
savefile.write("N     0\n6-31G(d')\n****\n")
savefile.write("C     0\n6-31G\n****\n")
savefile.write("H     0\n6-31G\n****\n")
savefile.write("\nradii=uff\nalpha=1.2\neps=4.0\n\n\n\n")

savefile.close()

#Write Psi inputfile

psiname = pdbnamesplit + ".psi"
psifile = open(psiname, "w")

psifile.write("memory 30GB\n\n")
psifile.write("molecule " + res1inter + str(res1) + "_" + res2inter + str(res2) + " {\n")
psifile.write(str(res1charge) + " 1\n")
psifile.write("RES1 " + str(len(fisaptlineA1 + fisaptlineA2)) + "\n")

psifile.write("--\n")

psifile.write(str(res2charge) + " 1\n")
psifile.write("RES2 " + str(len(fisaptlineB1 + fisaptlineB2)) + "\n")

psifile.write("\n     units angstrom\n")
psifile.write("     no_reorient\n")
psifile.write("     symmetry c1\n}\n\n")
psifile.write("set globals {\n")
psifile.write("    basis     jun-cc-pvdz\n")
psifile.write("    df_basis_scf  jun-cc-pvdz-jkfit\n")
psifile.write("    df_basis_sapt jun-cc-pvdz-ri\n")
psifile.write("    guess     sad\n")
psifile.write("    scf_type  df\n")
psifile.write("    freeze_core true\n")
psifile.write("}\n\n")
psifile.write("set sapt {\n")
psifile.write("    print     1\n")
psifile.write("}\n\n")
psifile.write("energy('fisapt0')")

psifile.close()
print("\tPsi4 template generated for " + str(res1) + "_" + str(res2))

#Write FISAPT fA.dat and fB.dat files

fAname = pdbnamesplit + ".fA"
fAfile = open(fAname, "w")
fAfile.write("AA ")
for item in fisaptlineA1:
    fAfile.write(str(item) + " ")
fAfile.write("\nAB ")
for item in fisaptlineA2:
    fAfile.write(str(item) + " ")
fAfile.close()

fBname = pdbnamesplit + ".fB"
fBfile = open(fBname, "w")
fBfile.write("BA ")
for item in fisaptlineB1:
    fBfile.write(str(item) + " ")
fBfile.write("\nBB ")
for item in fisaptlineB2:
    fBfile.write(str(item) + " ")
fBfile.close()
