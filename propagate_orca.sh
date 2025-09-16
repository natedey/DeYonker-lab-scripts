#!/bin/bash
# propagate_orca.sh {arg1} {arg2}
# Created Sep 2024
# DAW

if [ "$1" == "--help" ]; then
	echo "This script takes two args. Arg1 = orca file name, arg2 = renaming label. It copies {arg1}.inp to ?-{arg2}-inp, {arg1}.out to ?-{arg2}-out, {arg1}.gbw to ?-{arg2}-gbw and {arg1}.hess to ?-{arg2}-hess. Counts the number of {arg1}.inp files in the dir to number the saved file."
	exit
elif [ -z "$1" ] && [ -z "$2" ]; then
        echo "You must give two arguments: orca file name and renaming label!"
        exit
elif [ -n "$1" ] && [ -z "$2" ]; then
	echo "You must give two arguments: orca file name and renaming label!"
        exit
fi


count=(`ls -lt | grep -e -inp -e $1.inp | wc -l`)
#echo $count "is number of items"

check=(`ls -lrt | grep -v slurm | awk '{print $9}' | cut -d. -f1 | grep -E "$count-.*-out" | wc -l`)
check1=(`ls -lrt | grep -v slurm | awk '{print $9}' | cut -d. -f1 | grep -E "$count-.*-out"`)
#echo $check1
#echo $check
if [ "$count" == "0" ]; then
  echo "No $1.inp or fail files found!"
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
  if cmp -s $last $1.out; then
    echo "already propagated: $1.out and $last are the same file"
    exit
  fi
fi

cp -i $1.inp $count-$2-inp
cp -i $1.out $count-$2-out
if [ -f $1.gbw ]; then
	cp -i $1.gbw $count-$2-gbw
fi
if [ -f $1.hess ]; then
	cp -i $1.hess $count-$2-hess
fi

ls
