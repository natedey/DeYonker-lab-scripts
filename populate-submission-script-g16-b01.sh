#!/bin/bash
#populates directories with submission scripts

mycwd="`pwd`"

numberone=(`find ./ -type f -name 1`)
numberdir=(`find ./ -type d`)

if [ ${#numberone[*]} != $((${#numberdir[*]}-1)) ]; then
echo not all directories have a 1 file
#fi
#if [ ${#numberone[*]} = 0 ]; then
 if [ ${#numberone[*]} = 0 ]; then
  echo 1 files were not present
# elif [ ${#numberone[*]} > 0 ]; then
 elif [ ${#numberone[*]} -gt 0 ]; then
  echo some 1 files were present
 fi
 for (( i = 1 ; i < ${#numberdir[@]} ; i++ ))
  do
   if [ -f $mycwd/${numberdir[$i]}/1 ]; then
    echo already exists: $mycwd/${numberdir[$i]}/1
   else
    echo "adding 1 file:  ${numberdir[$i]}"
    cp /home/$USER/newbin/submission_scripts/script-g16-b01 $mycwd/${numberdir[$i]}/1
   fi
  done

else

 echo using existing 1 files
 for (( i = 0 ; i < ${#numberone[@]} ; i++ ))
  do
   echo ${numberone[$i]}
   cp /home/$USER/newbin/submission_scripts/script-g16-b01 $mycwd/${numberone[$i]}
  done
fi
