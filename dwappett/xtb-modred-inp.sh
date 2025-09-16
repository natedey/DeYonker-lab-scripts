#!/bin/bash

### script to write xtb inputs and then add modred ts constraints to input file
### usage: xtb-modred-inp.sh [pdb] [lig name]

if grep -qv $2 $1; then
    sed -i "s/TSA A 203/COR A 128/" $1
    for i in $(grep -n COR $1 | awk -F : '{print $1}'); do
        sed -i "${i}s/HETATM/ATOM  /" $1
    done
fi

bond1a=$(awk -v lig="$2" '$4 == lig && $3 == "C1" {print $2}' $1)
bond1b=$(awk -v lig="$2" '$4 == lig && $3 == "C9" {print $2}' $1)
bond2a=$(awk -v lig="$2" '$4 == lig && $3 == "C5" {print $2}' $1)
bond2b=$(awk -v lig="$2" '$4 == lig && $3 == "O7" {print $2}' $1)

write_input.py -format gau-xtb -pdb $1 -c -2

sed -i "s/ opt(nomicro) / opt(nomicro,modred) /" 1.inp
echo "$bond1a $bond1b F" >> 1.inp
echo "$bond2a $bond2b F" >> 1.inp
echo  >> 1.inp


