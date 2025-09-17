#!/bin/bash
# DAW 2025-09-17
# usage: gen_g16_jobscript.sh
# creates g16 slurm submission script/1 file
# sets no. processors/cpus and mem based on input file info


# use template 1 file from same directory as this script
tmpf=$(dirname "$0")/1-g16
cp $tmpf ./1

nprocs=$(grep "%nprocshared=" 1.inp | sed "s/%nprocshared=//")
totmem=$(grep "%mem=" 1.inp | sed "s/%mem=//; s/GB//")
cpumem=$(( totmem / nprocs ))

sed -i "s/NPROC/$nprocs/; s/CPUMEM/${cpumem}GB/" 1
