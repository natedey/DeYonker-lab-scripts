#!/bin/bash
# CEW 08/26/2010
# usage:
#
# write-openlog.sh (arg1) where the valid arg1 is list or --help
#

#test for no first argument and if "list" file exists
if [ -z "$2" ] && [ -f list ]; then
directories=( `cat list` )
elif [ -n "$2" ]; then
directories=( `cat $2` )
else
echo "there is no list file"
m=1
fi

if [ "$1" = "--help" ]; then
echo "This script writes an open.log file for use with cerius;
it uses the \"list\" file

write-openlog.sh arg1 (which is \$1) (arg2)
arg1 is the directory to insert on the open.log file
arg2 is the name of a list file not named \"list\"
"
else


if [ -z "$m" ]; then

echo "use --help for the command line argument to get directions

use these scripts to prepare, open, and match models
prepare-list.sh
write-openlog.sh
write-matchmodel.sh

nedit open.log&
"

#if [ 1 == 0 ]; then
if [ -f calcbond ]; then
 calcbond=1
 echo "calculating bonding is ON
turn it off by removing the calcbond file in the current directory"
else
 echo "calculating bonding is OFF
turn it on by creating a file named calcbond in the current directory"
fi


if [ -z "$2" ] ; then
echo "#open.log written by write-openlog.sh for list in `pwd`/list" > open.log
else
echo "#open.log written by write-openlog.sh for list in `pwd`/$2" > open.log
fi

echo "_GUI/MODAL 1" >> open.log
echo "_SYSTEM/REINIT_ALL" >> open.log
echo "VIEW/OVERLAY" >> open.log
echo "EDIT/INHIBIT_S_BONDS  NO" >> open.log

for i in "${directories[@]}"
do
#  if [ $i != "./" ]; then
# clean up the name of the directory to remove "/" from the name
     j=$(echo $i|sed -e 's%/$%%g' -e 's%/%-%g' -e 's%\.-%\.\/%g')
#    echo corrected directory name is $j

if [ -n "$1" ]; then
echo "FILES/LOAD  \"/home/$USER/$1/$j-out.msi\"" >> open.log
 if [ "$calcbond" = 1 ]; then
  echo "EDIT/CALCULATE_BONDING" >> open.log
 fi
else
echo "FILES/LOAD  \"./$j-out.msi\"" >> open.log
 if [ "$calcbond" = 1 ]; then
  echo "EDIT/CALCULATE_BONDING" >> open.log
 fi
fi

done

echo "
#here are the save commands" >> open.log
echo "FILES/SAVE_FORMAT  MSI"  >> open.log

for i in "${directories[@]}"
do
#  if [ $i != "./" ]; then
# clean up the name of the directory to remove "/" from the name
     j=$(echo $i|sed -e 's%/$%%g' -e 's%/%-%g' -e 's%\.-%\.\/%g')
#    echo corrected directory name is $j

echo "MODEL/SET_CURRENT Model($j-out)"  >> open.log
if [ -n "$1" ]; then
echo "_GUI/MODAL 1" >> open.log
echo "FILES/SAVE  \"/home/$USER/$1/$j-out.msi\"" >> open.log
else
echo "FILES/SAVE  \"./$j-out.msi\"" >> open.log
fi

done

fi
fi
