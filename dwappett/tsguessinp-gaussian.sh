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

write_input.py -format gaussian -pdb tsguess.pdb -c -2

sed -i "s/ opt / opt(modred) /" 1.inp
sed -i "s/C     0/$bond1a $bond1b F\n$bond2a $bond2b F\n\nC     0/" 1.inp
