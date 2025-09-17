#!/bin/bash
# DAW 2025-09-17
# usage: gen_psi4_jobscript.sh
# creates psi4 slurm submission script/1 file
# sets no. processors/cpus based on input file info. mem is left as 10GB per cpu as write_input default does 150GB for fsapt
# assumes input file is input.dat


# use template 1 file from same directory as this script
tmpf=$(dirname "$0")/1-psi4
cp $tmpf ./1

nprocs=$(grep "set_num_threads" input.dat | sed "s/set_num_threads(//; s/)//")

sed -i "s/NPROC/$nprocs/" 1
