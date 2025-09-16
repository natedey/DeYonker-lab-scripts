#!/bin/bash
# CEW 06/25/2013
# usage:
# test-completion.sh (arg1) where the valid arg1 is a list file or --help
#
# DAW modifications 2025-04 for more natural input syntax


if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
echo "DAW modified version of test-completion.sh

\$ test-completion-daw.sh
runs on current dir and all subdirs

\$ test-completion-daw.sh dir [dir2 ...]
runs on specified dirs and their subdirs
"
exit
fi

### DAW inps:
if [ -z "$1" ]; then
 echo "processing all 1.out files in all subdirectories"
 directories=( `find ./ -type d | sort` )
else
  sortinp=$(echo $@ | xargs -n1 | sort | xargs)
  for var in $sortinp; do
    if [[ -d $var ]]; then
      directories+=($var)
      subdir=$(find $var -type d)
      for s in ${subdir[@]}; do
        if [ "$s" != "$var" ]; then
          directories+=($s)
        fi
      done
    fi
  done
fi
###

for i in "${directories[@]}"
do

# make sure the 1.out file exists
     if [ -f $i/1.out ];then
      if [ ! -s $i/1.out ]; then
       echo "1.out is empty:" $i
      else

# check to see if the job completed normally
#echo it is $i/1.out
       if [ "`tail -n 1 $i/1.out |awk '{print $1, $2}'`" == "Normal termination" ]; then
        if [ -f $i/coords ]; then
         echo "completed and coords:" $i/1.out
        else
         echo "completed:           " $i/1.out
        fi
       elif [ -n "`tail -n 30 $i/1.out | grep Error`" ] || [ -n "`grep 'In source file ml0.f' $i/1.out`" ] ; then
         echo "failed:              " $i/1.out
       elif [ -n "`tail -n 5 $i/1.out | grep "Molpro calculation terminated"`" ]; then
         echo "Molpro completed:    " $i/1.out
       elif [ -n "`tail -n 30 $i/1.out | grep 'Buy a developer a beer'`" ] ; then
         echo "PSI4 completed:    " $i/1.out
       else
         echo "incomplete:          " $i/1.out
       fi
      fi
     elif [ -f $i/OPT.out ];then
       if [ -n "`tail -n 5 $i/OPT.out | grep "ORCA TERMINATED NORMALLY"`" ]; then
         echo "ORCA completed:      " $i/OPT.out
       fi
     else
      echo "1.out does not exist:" $i
     fi
done
