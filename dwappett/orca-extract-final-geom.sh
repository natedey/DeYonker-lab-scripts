#!/bin/bash

# DAW Nov/Dec 2025
# Extracts optimized geometry from orca output to xyz coords. Use if opt+freq calc runs out of time during the freq part and orca.xyz not copied over
# $1 = filename to extract from

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
echo "
This script extracts the final optimized geometry from an orca output file. 
Use when job crashes in freq part and orca.xyz doesn't get copied from /scratch/
usage: orca-extract-final-geom.sh arg1
arg1 = orca output file
"
exit
fi

natoms=$(grep "Number of atoms" $1 | awk 'NR==1 {print $NF}')
ngrep=$(( $natoms + 5 ))
xyzname=${1//.out/.xyz}
echo "$natoms" > $xyzname
echo "extracted from $1" >> $xyzname
grep -A $ngrep "FINAL ENERGY EVALUATION AT THE STATIONARY POINT" $1 >> $xyzname
sed -i "/\*/d; /-/d; /CARTESIAN COORDINATES/d" $xyzname
