#!/bin/bash

### run TSA replacement script
if [[ "$2" == "md" ]]; then
    align_TSA_and_replace.py -modpdb $1 -md
else
    align_TSA_and_replace.py -modpdb $1
fi


### create input from tsguess structure and then add lines for freezing bonds
# get atom numbers
bond1a=$(awk '$4 == "TSA" && $3 == "C1" {print $2}' tsguess.pdb)
bond1b=$(awk '$4 == "TSA" && $3 == "C9" {print $2}' tsguess.pdb)
bond2a=$(awk '$4 == "TSA" && $3 == "C5" {print $2}' tsguess.pdb)
bond2b=$(awk '$4 == "TSA" && $3 == "O7" {print $2}' tsguess.pdb)

write_input.py -format gau-xtb -pdb tsguess.pdb -c -2

sed -i "s/ opt(nomicro) / opt(nomicro,modred) /" 1.inp
#sed -i "s/C     0/$bond1a $bond1b F\n$bond2a $bond2b F\n\nC     0/" 1.inp
echo "$bond1a $bond1b F" >> 1.inp
echo "$bond2a $bond2b F" >> 1.inp
echo  >> 1.inp

### relabel ligand to COR for MD strucs for clarity
if [[ "$2" == "md" ]]; then
    sed -i "s/TSA A 203/COR A 128/" tsguess.pdb
    for i in $(grep -n COR tsguess.pdb | awk -F : '{print $1}'); do 
        sed -i "${i}s/HETATM/ATOM  /" tsguess.pdb
    done
fi
