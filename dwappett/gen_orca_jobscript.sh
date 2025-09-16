#!/bin/bash

# copy orca slurm submission script and modify based on specified input file

cp ~/orca_inputs/ORCA_job.sh .

inpn=${1%".inp"}
nprocs=$(grep "nprocs" $1 | awk '{print $3}')
mempercore=$(grep -m 1 "maxcore" $1 | awk '{print $2}')
totmem=$(( $nprocs * $mempercore / 1000))

sed -i "s/NPROC/$nprocs/; s/TOTMEM/${totmem}GB/; s/INPN/$inpn/" ORCA_job.sh
