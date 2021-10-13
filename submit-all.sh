#!/bin/bash
# CEW 06/01/2010
# usage:
#
# submit-all.sh
#
## the script changes to all subdirectories with a 1 file and submits the job
#

#make an array for the directories
if [ "$1" = "--help" ]; then
echo "
this script changes to all subdirectories with a 1 file and prints the commands
necessary to submit the jobs to the penguin queue.
As a safeguard, 
this output must then be copied and pasted into the window
"
else
directories=( `find ./ -type d` )

echo " "
#echo for loop without one and add /1 with a zpe
 for i in "${directories[@]}"
  do

# clean up the name of the directory to remove "./" from the name
     i=$(echo $i|sed 's%\.\/%%g')

# don't worry about the the current directory
   if [ "$i" != "./" ]; then
    if test -f $i/1; then
     echo cd `pwd`/$i
     echo sbatch 1
    fi
   fi
  done
fi

