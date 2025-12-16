#!/bin/bash

# DAW Nov/Dec 2025
# Extracts optimized geometry from orca output to xyz coords. Use if opt+freq calc runs out of time during the freq part and orca.xyz not copied over
# $1 = filename to extract from
# $2 = length of struc

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
echo "
This script extracts the final optimized geometry from an orca output file. 
Use when job crashes in freq part and orca.xyz doesn't get copied from /scratch/
usage: orca-extract-final-geom.sh arg1 arg2
arg1 = orca output file
arg2 = number of atoms in structure
if you have a template pdb with file length = number of atoms, 
then you can run like this to avoid checking the size manually:
orca-extract-final-geom.sh arg1 $(cat template.pdb | wc -l)
"
exit
fi


ngrep=$(( $2 + 5 ))
echo "$2" > tsconstrained.xyz
echo "extracted xyz" >> tsconstrained.xyz
grep -A $ngrep "FINAL ENERGY EVALUATION AT THE STATIONARY POINT" $1 >> tsconstrained.xyz
sed -i "/\*/d; /-/d; /CARTESIAN COORDINATES/d" tsconstrained.xyz
