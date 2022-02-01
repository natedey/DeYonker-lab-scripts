#!/bin/bash
# CEW 08/26/2010
# usage:
#
# write-matchmodel.sh (arg1) where the valid arg1 is list or --help
#

#test for no first argument and if "list" file exists
if [ -z "$1" ] && [ -f list ]; then
directories=( `cat list` )
elif [ -n "$1" ]; then
directories=( `cat $1` )
else
echo "there is no list file"
m=1
fi

if [ "$1" = "--help" ]; then
echo "This script writes a match.log

write-matchmodel.sh arg1 (which is \$1)
arg1 is the \"list\" file that names directories to use
"
else


if [ -z "$m" ]; then

echo "use --help for the command line argument to get directions

use these scripts to prepare, open, and match models
prepare-list.sh
write-openlog.sh
write-matchmodel.sh

nedit match.log&
"

if [ -z "$1" ] ; then
echo "#match.log written by write-matchmodel.sh for list in `pwd`/list" > match.log
else
echo "#match.log written by write-matchmodel.sh for list in `pwd`/$1" > match.log
fi
#echo "_GUI/MODAL 1" >> match.log
#echo "_SYSTEM/REINIT_ALL" >> match.log
echo "VIEW/OVERLAY" >> match.log

 for i in ${directories[@]}
 do
  cleandir=( "${cleandir[@]}" `echo $i | sed 's%/%-%g' | sed 's%\.-%\.\/%g'` )
 done

     echo "MODEL/SET_CURRENT Model(${cleandir[0]}-out)"   >> match.log
     echo "SELECT/ATOM_PROPERTY  ID"                         >> match.log
     echo "SELECT/ATOM_PROPERTY_VALUE  \"1,2,3,4\" "         >> match.log
     echo "SELECT/SELECT_OBJREF "                            >> match.log
     echo "MOVE/REFERENCE_MODEL  \"${cleandir[0]}-out\" " >> match.log

 for (( k = 1 ; k < ${#cleandir[*]} ; k++ ))
 do
     echo "MOVE/FIT_MODEL  \"${cleandir[k]}-out\"" >> match.log
     echo "MODEL/SET_VISIBLE"          >> match.log
     echo "MOVE/MATCH_MODELS"          >> match.log
 done

fi
fi
