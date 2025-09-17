#!/bin/bash
# DAW 2024-12-18
# usage: gen_orca_jobscript.sh [optional inp file name]
# creates orca slurm submission script/1 file
# sets input name, no processors/cpus, mem based on input file info
# copy orca slurm submission script and modify based on specified input file


# use template 1 file from same directory as this script
tmpf=$(dirname "$0")/1-orca6
cp $tmpf ./1

# use orca.inp by default, otherwise specified name. name defined without ".inp" suffix so job script can do name.inp > name.out
if [ -z $1 ]; then
 inpn="orca"
elif [[ "$1" == *".inp" ]]; then
 inpn=${1%.inp}
else
 inpn=$1
fi

nprocs=$(grep "nprocs" ${inpn}.inp | awk '{print $3}')
mempercore=$(grep -m 1 "maxcore" ${inpn}.inp | awk '{print $2}')
totmem=$(( $nprocs * $mempercore / 1000 ))

sed -i "s/NPROC/$nprocs/; s/TOTMEM/${totmem}GB/; s/INPN/$inpn/" 1
