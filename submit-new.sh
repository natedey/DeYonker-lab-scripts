#!/bin/bash
# CEW 04/05/2011
# usage:
#
# submit-new.sh
#
## the script writes the commands to submit the jobs for all subdirectories with a 1 file and no 1.out file
#

if [ "$1" = "--help" ]; then
echo "
this script changes to all subdirectories with a 1 file but no 1.out file
and prints the commands necessary to submit the jobs to the penguin queue.
As a safeguard,
this output must then be copied and pasted into the window
"
else
#make an array for the directories
directories=( `find ./ -type d` )
#directories=( `find ./ -type d -amin -10` )

echo " "
#echo for loop without one and add /1 with a zpe
 for i in "${directories[@]}"
  do

# clean up the name of the directory to remove "./" from the name
     i=$(echo $i|sed 's%\.\/%%g')

# don't worry about the the current directory
   if [ "$i" != "./" ]; then
    if [ -f $i/1 ] && [ ! -f $i/1.out ]; then
     echo cd `pwd`/$i
     echo sbatch 1
    fi
   fi
  done
fi
