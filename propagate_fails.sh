#!/bin/bash
# propagate_fails-new.sh {arg1}
# Created 12-05-2012
# NJD
 
# changed the format so that it a) keeps the script files (named .job) and b) iterates no matter what the argument is
# so that the order will always be constant if timestamps on files become messed up

if [ -z "$1" ]; then
echo "
You must give an argument for the file renaming!"
exit
fi

if [ "$1" == "--help" ]; then
echo "
This script takes an {arg1} and copies your input (1.inp), output (1.out), a Gaussian script file, and checkpoint file (1.chk) 
to ?-{arg1}-inp, ?-{arg1}-out, and ?-{arg1}-chk, respectively. This script will look in the current working directory
for the existence of previously numbered ?-{arg1}-??? files and iterate accordingly. When tested and checked into the svn
repository, this script should NEVER overwrite anything!"
exit
fi

count=(`ls -lt | grep inp | wc -l`)
#echo $count "is number of items"

check=(`ls -lrt | grep -v slurm | awk '{print $9}' | cut -d. -f1 | grep "$count" | wc -l`)

if [ "$count" == "0" ]; then
  echo "No 1.inp or fail files found!"
  exit
fi

if [ "$count" != "1" ]; then
  if  [ "$check" != "0" ]; then
    echo something is amiss. Files with the $count prefix already exist
    echo you may need to renumber fail files. Be careful!
    exit
fi
fi

#echo $count
#echo "renaming to" $count"-"$1
cp -i 1.inp $count-$1-inp
cp -i 1.out $count-$1-out
cp -i 1.chk $count-$1-chk
