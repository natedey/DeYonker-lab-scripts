#!/bin/bash
# propagate_orca.sh {arg1} {arg2}
# Created Sep 2024
# DAW

if [ "$1" == "--help" ] || [ "$1" == "-h" ] ; then
	echo "This script takes up to two args. Arg1 = renaming label, arg2 = orca base file name (default orca)
It copies orca/{arg2}.inp to ?-{arg1}-inp, orca/{arg2}.out to ?-{arg1}-out, orca/{arg2}.gbw to ?-{arg1}-gbw and orca/{arg2}.hess to ?-{arg1}-hess. 
Counts the number of inp files in the dir to number the saved file."
	exit
elif [ -z "$1" ] && [ -z "$2" ]; then
        echo "You must give a renaming label!"
        exit
elif [ -n "$1" ] && [ -z "$2" ]; then
	set -- "$1" "orca"
fi

count=(`ls -lt | grep -e -inp -e $2.inp | wc -l`)
#echo $count "is number of items"

check=(`ls -lrt | grep -v slurm | awk '{print $9}' | cut -d. -f1 | grep -E "$count-.*-out" | wc -l`)
check1=(`ls -lrt | grep -v slurm | awk '{print $9}' | cut -d. -f1 | grep -E "$count-.*-out"`)
#echo $check1
#echo $check
if [ "$count" == "0" ]; then
  echo "No $2.inp or fail files found!"
  exit
fi

if [ "$count" != "0" ]; then
  if  [ "$check" != "0" ]; then
    echo something is amiss. $check Files with the $count prefix already exist
    echo you may need to renumber $check1 files. Be careful!
    exit
fi
fi

if [[ "$count" -gt 1 ]]; then
  last=$(ls $((count - 1))-*-out)
  if cmp -s $last $2.out; then
    echo "already propagated: $2.out and $last are the same file"
    exit
  fi
fi

cp -i $2.inp $count-$1-inp
cp -i $2.out $count-$1-out

# before propagating xyz/gbw/hess/trjxyz, check that they're new files to avoid mismatched propagation when stuff wasn't copied back from the scratch dir
for i in xyz gbw xtbw hess; do
 if [ -f $2.$i ]; then
  unique=1
  if [[ "$count" -gt 1 ]]; then
   for ((j=1;j<$count;j++)); do
    if [ -f $j-*-$i ] && cmp -s $j-*-$i $2.$i; then unique=0; fi
   done
  fi
  if [[ "$unique" == 1 ]]; then
   cp -i $2.$i $count-$1-$i
  fi
 fi
done
if [ -f $2_trj.xyz ]; then
 unique=1
 if [[ "$count" -gt 1 ]]; then
  for ((j=1;j<$count;j++)); do
   if [ -f $j-*-trjxyz ] && cmp -s $j-*-trjxyz $2_trj.xyz; then unique=0; fi
  done
 fi
 if [[ "$unique" == 1 ]]; then
  cp -i $2_trj.xyz $count-$1-trjxyz
 fi
fi

ls
