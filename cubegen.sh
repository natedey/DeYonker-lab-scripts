#!/bin/bash
# CEW 12/03/2010
# usage:
#
# cubegen.sh arg1 arg2 (arg3)
#
## the script will make a 1.fchk file and generate cube files
#
# cubegen.sh arg1 arg2 (arg3)
# arg1 is the name of middle of the file to use for the cube file
# arg2, arg3, etc are the orbital numbers
#

one=$1

if [ -z "$1" ]; then
echo "you did not specify a name, give a name as arg1
"
one="--help"
fi

if [ "$one" = "--help" ]; then
echo "This script makes a 1.fchk file (if needed) and generates cube files

usage:
cubegen.sh arg1 arg2 (arg3)
arg1 is the name of middle of the file to use for the cube file name
arg2, arg3, etc. are the orbital numbers
e.g.,
cubegen.sh complex1 78
would generate the cube file named 78.complex1.cube

in the bottom of the script file, the \$USER and ip address
to which to send files, must be personalized
"
else

export g09root=/home/webster/g09_a02/806
. $g09root/g09/bsd/g09.profile

# test if the chk exists
if [ -f 1.chk ]; then
# test if the fchk already exists
 if [ ! -f 1.fchk ]; then
 printf "generating the fchk file:\n"
 formchk 1.chk
 printf "\n"
 else
 echo the fchk file already exists!
 fi
else
 echo 1.chk file does not exist!
 exit
fi

echo the alpha HOMO is orbital number `grep NAE 1.out | awk '{print $4 }' |head -1`

#set the value of name with the "$1" variable, which is the first command-line argument
name=$1

#populate the array with "$@" variable, which expands to all command-line arguments separated by spaces
moarray=($@)

if [ ${#moarray[@]} = 1 ]; then
echo "you did not specify a MO number, we will just create the HOMO cube file"
moarray[1]=`grep NAE 1.out | awk '{print $4 }' |head -1`
fi

# skip ${moarray[0]} because it is $1, which is the "name"
for (( i = 1 ; i < ${#moarray[@]} ; i++ ))

do

 printf "\n"
 echo generating cubefile for MO ${moarray[$i]}:

# test if the cube already exists
 if [ ! -f ${moarray[$i]}.$1.cube ]; then
  echo " cubegen 0 mo=${moarray[$i]} 1.fchk ${moarray[$i]}.$1.cube -2 h"
  cubegen 0 mo=${moarray[$i]} 1.fchk ${moarray[$i]}.$1.cube -2 h
 else
 echo ${moarray[$i]}.$1.cube already exists!
 fi


done

 printf "\n"
 printf "use this command to copy the files\n"
# one should personalize this echo, then issue the command and open the cube files with AGUI
for (( i = 1 ; i < ${#moarray[@]} ; i++ ))
do
 echo "scp ${moarray[$i]}.$1.cube $USER@141.225.147.5:"
done

fi
