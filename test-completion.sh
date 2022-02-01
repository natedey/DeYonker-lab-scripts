#!/bin/bash
# CEW 06/25/2013
# usage:
#
# test-completion.sh (arg1) where the valid arg1 is a list file or --help
#

script_name="test-completion"

if [ "$1" = "--help" ]; then
echo "This script tests output files for normal completion

$script_name.sh arg1
arg1 is directory to process

$script_name.sh list arg2
arg1 is list
arg2 is a \"list\" file that names directories to check

$script_name.sh './ -type d -name ts10 -o -name ts11 -o -name ts12'
will use the all command line arguments for a find command
**note** the single quotes are required!
"
exit
fi

if [ -z "$1" ]; then
 echo "processing all 1.out files in all subdirectories"
 directories=( `find ./ -type d | sort` )
elif [ -n "$1" ] && [ -d "$1" ]; then
 echo "processing directory: $1"
 directories="$1"
elif [ "$1" == "list" ] && [ -n "$2" ]; then
 if [ -f "$2" ]; then
  directories=( `cat $2` )
  echo "using $2 file for test-completion.sh"
 else
  echo exiting... you requested to use a list file, but $2 does not exist
  exit 
 fi
elif [ "$1" == "list" ] && [ -z "$2" ]; then
  echo exiting... you requested to use a list file, but did not specify the file
  exit 
else
 find_stuff=`echo $@`
 echo expanding the command-line arguments to use in the find command
 echo "files=(\`find $find_stuff\`)"
 directories=(`eval find $find_stuff`)
fi

echo "use --help for the command line argument to get directions
"

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
