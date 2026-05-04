#!/bin/bash
# DAW script for submitting jobs to run sequentially with dependencies
# created Feb 2026

if [ -z $1 ]; then
 echo "please specify dirs!"
 exit
elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
 echo "usage: submit-dependent.sh [dirs]
this script submits the 1 files in the given dirs with job dependencies
so that each one can't start until the previous one has finished
as an alternative to setting up a slurm array with arraytaskthrottle=1"
 exit
elif [ -f $1 ]; then
 echo "script takes folder names directly but a file has been given"
 echo "please run as:  submit-dependent.sh \$(cat $1)"
 exit
fi

wkdr=$(pwd)
# go into first directory, submit and capture job id
cd $1
ID=$(sbatch --parsable 1)
echo "directory $1: submitted job ${ID}"
cd $wkdr
# shift removes first arg from $@ input argument list
shift
# now we can easily loop through the remaining dirs, building the dependencies
for i in "$@"; do
 cd $i
 ID=$(sbatch --parsable --dependency=afterany:${ID} 1)
 echo "directory $i: submitted job ${ID}"
 cd $wkdr
done
