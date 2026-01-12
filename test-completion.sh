#!/bin/bash
# CEW 06/25/2013
# usage:
# test-completion.sh (args) where the args are --help or list + file or directory names
# DAW 2025-04 modified for more natural input syntax 

script_name="test-completion"

if [ "$1" = "--help" ]; then
echo "This script tests output files for normal completion. Usage options:
> test-completion.sh 
tests output files in the current directory and its subdirectories
> test-completion.sh [directory or directories]
tests output files in the listed directory/ies and subdirectories
> test-completion.sh list [file that lists directories to check]
tests output files in directories listed in the provided file
"
exit
fi

if [ -z "$1" ]; then
 echo "processing all 1.out files in all subdirectories"
 echo "use argument --help for other options"
 directories=( `find ./ -type d | sort` )
elif [ "$1" == "list" ]; then
 if [ -n "$2" ] && [ -f "$2" ]; then
  directories=( $(cat $2) )
 else
  echo "please specify list file"
 fi
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

for i in "${directories[@]}"; do
# make sure the 1.out file exists
 if [ -f $i/1.out ]; then
  if [ ! -s $i/1.out ]; then
   echo "1.out is empty:      " $i
  else
  # check to see if the job completed normally
   if [ "`tail -n 1 $i/1.out |awk '{print $1, $2}'`" == "Normal termination" ]; then
    if [ -f $i/coords ]; then
     echo "completed and coords:" $i/1.out
    else
     echo "completed:           " $i/1.out
    fi
   elif [ -n "`tail -n 30 $i/1.out | grep Error`" ] || [ -n "`grep 'In source file ml0.f' $i/1.out`" ] || [ -n "`tail -n 5 $i/1.out | grep "aborting the run"`" ]; then
     echo "failed:              " $i/1.out
   elif [ -n "`tail -n 5 $i/1.out | grep "Molpro calculation terminated"`" ]; then
     echo "Molpro completed:    " $i/1.out
   elif [ -n "`tail -n 30 $i/1.out | grep 'Buy a developer a beer'`" ] ; then
     echo "PSI4 completed:      " $i/1.out
   elif [ -n "`tail -n 15 $i/1.out | grep 'Thank you very much for using Q-Chem.'`" ] ; then
     echo "QChem completed:     " $i/1.out
   elif [ -n "`tail -n 5 $i/1.out | grep "ORCA TERMINATED NORMALLY"`" ]; then 
     echo "ORCA completed:      " $i/1.out
   else
     echo "incomplete:          " $i/1.out
   fi
  fi
 elif [ -f $i/OPT.out ]; then
  if [ ! -s $i/OPT.out ]; then
   echo "OPT.out is empty:    " $i
  else
   if [ -n "`tail -n 5 $i/OPT.out | grep "ORCA TERMINATED NORMALLY"`" ]; then
     echo "ORCA completed:      " $i/OPT.out
   elif [ -n "`tail -n 5 $i/OPT.out | grep "aborting the run"`" ]; then
     echo "ORCA failed:         " $i/OPT.out
   else
     echo "incomplete:          " $i/OPT.out
   fi
  fi
 elif [ -f $i/orca.out ]; then
  if [ ! -s $i/orca.out ]; then
   echo "orca.out is empty:   " $i
  else
   if [ -n "`tail -n 5 $i/orca.out | grep "ORCA TERMINATED NORMALLY"`" ]; then
     if grep -q "The optimization did not converge but reached the maximum" $i/orca.out; then
       echo "ORCA hit max cycles: " $i/orca.out
     else
       echo "ORCA completed:      " $i/orca.out
     fi
   elif [ -n "`tail -n 5 $i/orca.out | grep "aborting the run"`" ]; then
     echo "ORCA failed:         " $i/orca.out
   else
     echo "incomplete:          " $i/orca.out
   fi
  fi
 else
  echo "1.out does not exist:" $i
 fi
done
