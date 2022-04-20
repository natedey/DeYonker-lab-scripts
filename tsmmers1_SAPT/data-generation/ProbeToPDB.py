#!/usr/bin/env python

import os
import sys
import re

#Usage: fisapt_pdbgen.py probedata pdbfile

if (len(sys.argv) < 3 or len(sys.argv) > 3):
    print "\nUsage: genpdb_mc_isapt.py probedata pdbfile\n"
    sys.exit(0)

#Extract probe CSV data into list of lists
#       [0]     [1]     [2]     [3]         [4]     [5]     [6]         [7]     [8]     [9]         [10]    
#Format Name, Res1Num, Res1ID, Res1Atom, Res1Type, Res1Pos, Res2Num, Res2ID, Res2Atom, Res2Type, Res2Pos, WC, CC, SO, HB, Score
probedata = []
probefilename = sys.argv[1]
with open(probefilename) as probefile:
    for line in probefile:
        if line.split(",")[0] == "Name":
            continue
        divided = [x for x in line.split(",")]
        divided[1] =  int(divided[1])
        divided[5] =  int(divided[5])
        divided[6] =  int(divided[6])
        divided[10] = int(divided[10])
        probedata.append(divided)

#Extract pdb data 
#Line formst: ATOM,  AtomNumber,  Atom,  Residue,  ResidueNumber,  X, Y, Z, 1.00, 0.00
pdbfilename = sys.argv[2]
pdbfile = open(pdbfilename)
pdblines = pdbfile.readlines()
pdbfile.close()

#Functions for writing outputs
def mcmc_oneapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==num2:
                savefile.write(line)
            if int(line[22:26])==num1 or int(line[22:26])==(num2+1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
                    savefile.write(line)
            if int(line[22:26])==(num1-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==(num2+2):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
    savefile.close()

def mcmc_twoapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==(num2+2):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if(int(line[22:26])==num1 or int(line[22:26])==(num1+1) or int(line[22:26])==num2 or int(line[22:26])==(num2+1)):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
                    savefile.write(line)
    savefile.close()

def mcmc_threeapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==(num2+2):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if(int(line[22:26])==num1 or int(line[22:26])==(num1+1) or int(line[22:26])==(num1+2) or int(line[22:26])==num2 or int(line[22:26])==(num2+1)):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
                    savefile.write(line)
    savefile.close()

def mcmc_fourapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1) or int(line[22:26])==(num2-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==(num1+2) or int(line[22:26])==(num2+2):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if(int(line[22:26])==num1 or int(line[22:26])==(num1+1) or int(line[22:26])==num2 or int(line[22:26])==(num2+1)):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
                    savefile.write(line)
                if (int(line[22:26])==(num1+1) and line[17:21].strip()=="PRO" and line[11:17].strip()=="CD") or (int(line[22:26])==(num2+1) and line[17:21].strip()=="PRO" and line[11:17].strip()=="CD"):
                    savefile.write(line)
    savefile.close()

def mcsc_twoapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
    	if line.split()[0] == "ATOM":
    	    if int(line[22:26])==(num1-1):
        		if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
        		    savefile.write(line)
    	    if int(line[22:26])==(num2):
        		savefile.write(line)
            if int(line[22:26])==(num1+1) or int(line[22:26])==num1:
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
	            savefile.write(line)
            if int(line[22:26])==(num2+1):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
        	        savefile.write(line)
    savefile.close()

def mcsc_threeapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==(num2+1):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==num2:
                savefile.write(line)
            if int(line[22:26])==num1 or int(line[22:26])==(num1+1) or int(line[22:26])==(num1+2):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
                    savefile.write(line)
    savefile.close()

def mcsc_fourapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1) or int(line[22:26])==(num2-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==(num2+1) or int(line[22:26])==(num1+2):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==num2:
                savefile.write(line)
            if int(line[22:26])==num1 or int(line[22:26])==(num1+1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
                    savefile.write(line)
                if(int(line[22:26])==(num1+1) and line[16:21].strip()=="PRO" and line[11:17].strip()=="CD"):
                    savefile.write(line)
    savefile.close()

def scmc_oneapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==num1:
                savefile.write(line)
            if int(line[22:26])==num2 or int(line[22:26])==(num2+1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
                    savefile.write(line)
            if int(line[22:26])==(num2+2):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
    savefile.close()

def scmc_twoapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==num1:
                savefile.write(line)
            if int(line[22:26])==(num1+1) or int(line[22:26])==num2 or int(line[22:26])==(num2+1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
                    savefile.write(line)
            if int(line[22:26])==(num2+2):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
    savefile.close()

def scmc_threeapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1) or int(line[22:26])==(num2-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==num1:
                savefile.write(line)
            if int(line[22:26])==(num1+1) or int(line[22:26])==(num2+2):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==num2 or int(line[22:26])==(num2+1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
                    savefile.write(line)
                if(int(line[22:26])==(num2+1) and line[17:21].strip()=="PRO" and line[11:17].strip()=="CD"):
                    savefile.write(line)
    savefile.close()

def scsc_oneapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==num1 or int(line[22:26])==num2:
                savefile.write(line)
            if int(line[22:26])==(num2+1):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
    savefile.close()

def scsc_twoapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==num1 or int(line[22:26])==num2:
                savefile.write(line)
            if int(line[22:26])==(num1+1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA" or line[11:17].strip()=="N" or line[11:17].strip()=="H"):
                    savefile.write(line)
            if int(line[22:26])==(num2+1):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
    savefile.close()

def scsc_threeapart(name, num1, num2):
    savefilename = name + ".pdb"
    savefile = open(savefilename, "w")

    for line in pdblines:
        if line.split()[0] == "ATOM":
            if int(line[22:26])==(num1-1) or int(line[22:26])==(num2-1):
                if(line[11:17].strip()=="C" or line[11:17].strip()=="O" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
            if int(line[22:26])==num1 or int(line[22:26])==num2:
                savefile.write(line)
            if int(line[22:26])==(num1+1) or int(line[22:26])==(num2+1):
                if(line[11:17].strip()=="N" or line[11:17].strip()=="H" or line[11:17].strip()=="CA" or line[11:17].strip()=="HA"):
                    savefile.write(line)
    savefile.close()

def writelogfile(name):
    logfile = open("pymol.log","a")
    logfile.write("cmd.load(\"" + name + ".pdb" + "\")\n")
    logfile.write("cmd.h_add(\"not name ND1 and not name NE2\")\n")
    logfile.write("cmd.save(\"" + name + "H.pdb" + "\")\n")
    logfile.write("cmd.delete(\"all\")\n")
    logfile.close()

#Commands for outputs
for item in probedata:
#    if (item[4]=="MC" and item[9]=="MC" and (item[10]-item[5])==1):
#        mcmc_oneapart(item[0], item[5], item[10])
#        writelogfile(item[0])
#    if (item[4]=="MC" and item[9]=="MC" and (item[10]-item[5])==2):
#        mcmc_twoapart(item[0], item[5], item[10])
#        writelogfile(item[0])
#    if (item[4]=="MC" and item[9]=="MC" and (item[10]-item[5])==3):
#        mcmc_threeapart(item[0], item[5], item[10])
#        writelogfile(item[0])
    if (item[4]=="MC" and item[9]=="MC" and (item[10]-item[5])>=4):
        mcmc_fourapart(item[0], item[5], item[10])
        writelogfile(item[0])

#    if (item[4]=="MC" and item[9]=="SC" and (item[10]-item[5])==2):
#        mcsc_twoapart(item[0], item[5], item[10])
#        writelogfile(item[0])
#    if (item[4]=="MC" and item[9]=="SC" and (item[10]-item[5])==3):
#        mcsc_threeapart(item[0], item[5], item[10])
#        writelogfile(item[0])
    if (item[4]=="MC" and item[9]=="SC" and (item[10]-item[5])>=4):
        mcsc_fourapart(item[0], item[5], item[10])
        writelogfile(item[0])

#    if (item[4]=="SC" and item[9]=="MC" and (item[10]-item[5])==1):
#        scmc_oneapart(item[0], item[5], item[10])
#        writelogfile(item[0])
#    if (item[4]=="SC" and item[9]=="MC" and (item[10]-item[5])==2):
#        scmc_twoapart(item[0], item[5], item[10])
#        writelogfile(item[0])
    if (item[4]=="SC" and item[9]=="MC" and (item[10]-item[5])>=3):
        scmc_threeapart(item[0], item[5], item[10])
        writelogfile(item[0])

#    if (item[4]=="SC" and item[9]=="SC" and (item[10]-item[5])==1):
#        scsc_oneapart(item[0], item[5], item[10])
#        writelogfile(item[0])
#    if (item[4]=="SC" and item[9]=="SC" and (item[10]-item[5])==2):
#        scsc_twoapart(item[0], item[5], item[10])
#        writelogfile(item[0])
    if (item[4]=="SC" and item[9]=="SC" and (item[10]-item[5])>=3):
        scsc_threeapart(item[0], item[5], item[10])
        writelogfile(item[0])
