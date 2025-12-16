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
if [ -f $2.xyz ]; then
        cp -i $2.xyz $count-$1-xyz
fi
if [ -f $2.gbw ]; then
	cp -i $2.gbw $count-$1-gbw
fi
if [ -f $1.xtbw ]; then
        cp -i $2.xtbw $count-$1-xtbw
fi
if [ -f $1.hess ]; then
	cp -i $2.hess $count-$1-hess
fi

ls
