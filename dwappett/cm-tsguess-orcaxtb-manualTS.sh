#!/bin/bash

# orcaxtb-tsguess.sh {model pdb}
# DAW script for setting up constrained ts optimization with xtb in orca
# !!! specifically for chorismate mutase md models !!!

# generate tsguess.pdb
align_TSA_and_replace.py -modpdb $1 -md -tspdb $2
# change ts res name back to cor/record type back to atom to match original template pdb
#sed -i "s/HETATM/ATOM  /; s/TSA/COR/" tsguess.pdb
# create input file
write_input.py -pdb tsguess.pdb -format orca -intmp ~/git/DeYonker-lab-scripts/CM_MD_to_QM_project/orcaxtb_intmp.txt -c -2 -inpn orca.inp
# work out which bonds to constrain and add constraints to inp
bond1a=$(( $(awk '$4 == "COR" && $3 == "C1" {print $2}' tsguess.pdb) - 1 ))
bond1b=$(( $(awk '$4 == "COR" && $3 == "C9" {print $2}' tsguess.pdb) - 1 ))
bond2a=$(( $(awk '$4 == "COR" && $3 == "C5" {print $2}' tsguess.pdb) - 1 ))
bond2b=$(( $(awk '$4 == "COR" && $3 == "O7" {print $2}' tsguess.pdb) - 1 ))
sed -i "s/constraints/constraints\n  { B $bond1a $bond1b C }  #product bond\n  { B $bond2a $bond2b C }  #reactant bond/" orca.inp

#cp ~/git/DeYonker-lab-scripts/1-orcaxtb 1
