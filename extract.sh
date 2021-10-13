#!/bin/bash
# CEW 10/19/2011
# usage:
#
# extract.sh arg1
#
## the script will extract the computed energies and other information for 1.out files
#
# extract.sh arg1 (which is $1) arg2 (which is $2)
# arg1 = "warning" prints warning statements
# arg1 = "col" prints data in column format
# arg1 = "--help" prints the help for the script
#
# arg2 = "list" \"list\" file is read for which directories to process
#

#test for one argument and no second argument
if [ -n "$2" ] && [ "$2" = "list" ]; then
directories=( `cat list | grep -v "#"` )
elif [ "$1" = "list" ]; then
directories=( `cat list | grep -v "#"` )
#
elif [ -n "$2" ] && [ "$2" != "list" ]; then
directories=( `cat "$2" | grep -v "#"` )
elif [ -n "$1" ] && [ "$1" != "list" ] && [ "$1" != "col" ]; then
directories=( `cat "$1" | grep -v "#"` )
#or make an array for the directories
else
directories=( `find ./ -type d` )
fi

if [ "$1" = "--help" ]; then
echo "This script
1) prints the directory location of the output file
2) extracts computed energies (E, Eo, H, and G) from G03 and G09
     optimization output files (1.out)
3) extracts the number of imaginary freqencies
4) extracts the number of basis functions
5) with col command line argument, extracts data in column format

If the job is not an optimization, the script will print just the energy
and number of basis functions.

extract.sh (arg1) (arg2) (which are \$1 and \$2)
arg1:
\"warning\" prints warning statements
\"col\" prints data in column format
\"list\" uses the file \"list\" to decide which directories from which
         to extract data
any other arg1 uses the supplied name to decide which directories to read
e.g., \"arbitrary\" uses the file \"arbitrary\" to decide which
         directories from which to extract data
arg2:
\"list\" uses file \"list\" instead of all directories
any other arg2 uses the supplied name to decide which directories to read
e,g, \"arbitrary\" uses the file \"arbitrary\" to decide which directories
         from which to extract data

it can be very useful to redirect the output from this script to a file:
e.g., extract.sh >> data.txt
"
exit
fi


echo "use --help for the command line argument to get directions
"

#echo for loop without one and add /1 with a zpe
 for i in "${directories[@]}"
  do

# clean up the name of the directory to remove "./" from the name
     j=$(echo $i|sed 's%\.\/%%g')
#    echo corrected directory name is $j

# make sure the 1.out file exists
    if test -s $i/1.out; then
     anyoutput=1

     if [ "${1}" != "col" ]; then
      echo `pwd`/$j
     fi

# check to see if the job completed normally
      if [ "`tail -n 1 $i/1.out |awk '{print $1, $2}'`" = "Normal termination" ]; then

# the part of the script checks for a KJOB run by looking back 6 lines from the last line for "*Kjob"
# need to see if that line contains nothing (because if statements will not work with an empty argument)
       if [ ! -n `tail -n 6 $i/1.out |head -n 1 |awk '{print $1}'` ]; then
         STR="dummy variable"
# or if that line contains something
       else
         STR=`tail -n 6 $i/1.out | head -n 1 |awk '{print $1}'`
       fi

# if the string is empty, give it a value: ${STR:-0} instead of just $STR
# if the string is not "*Kjob", do stuff
       if [ ${STR:-0} != "*Kjob" ]; then

        if [ "${1}" != "col" ]; then

         egrep "Done|xtrapolated" $i/1.out | tail -n 1 | awk '{print $1 $2 $3 $4 $5}' ; grep 'Sum of e' $i/1.out
         
# find the number of lines needed to perform the tail command to get NImag
         lines=$(expr `grep -n "Normal termination" $i/1.out |awk -F: '{print $1}' |tail -1` - `grep -n "/l9999.exe" $i/1.out |awk -F: '{print $1}' |tail -1`)

# unfortunately, NImag is not always on the same line
# use awk to put all of this onto one line, find NImag and replace any spaces with sed
#         tail -n $lines $i/1.out |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \\ ' /NImag/ {for (i=1; i<=NF; i++) print $i;} /N  Imag/ {for (i=1; i<=NF; i++) print $i;} /NI  mag/ {for (i=1; i<=NF; i++) print $i;} /NIm  ag/ {for (i=1; i<=NF; i++) print $i;} /NIma  g/ {for (i=1; i<=NF; i++) print $i;} ' | sed 's/  //g' | grep "NImag" ; \
#         tail -n $lines $i/1.out | sed 's%\n %%g' |sed 's%N  Imag%NImag%g' |sed 's%NI  mag%NImag%g'|sed 's%NIm  ag%NImag%g'|sed 's%NIma  g%NImag%g'| awk -F \\ ' /NImag/ {for (i=1; i<=NF; i++) print $i;} ' | grep "NImag"
#         tail -n $lines $i/1.out | tr '\n' ' '  |sed 's%  %%g' | awk -F \\ ' /NImag/ {for (i=1; i<=NF; i++) print $i;} ' | grep "NImag"
#         grep -A5 "PG=" $i/1.out  | tr '\n' ' '  |sed 's%  %%g' | awk -F \\ ' /NImag/ {for (i=1; i<=NF; i++) print $i;} ' | grep "NImag"
#          tail -$lines $i/1.out  |tr '\\n' ' ' |sed 's%  %%g' |tr '\\' '\\n' |grep "NImag"
#          tail -$lines $i/1.out  |tr '\\n' ' ' |sed 's%  %%g' |tr '\\\' '\\n' |grep "NImag"
          nimag="`tail -$lines $i/1.out  |tr '\\n' ' ' |sed 's%  %%g' |tr '\\\' '\\n' |grep "NImag"`"
          echo $nimag
# get the number of basis functions
         grep NBasis $i/1.out| tail -n 1 | awk '{print $1 $2}'
         if [ "${1}" = "warning" ]; then
          grep 'arning' $i/1.out | grep -v 'arning -- This'
         fi

        fi

         if [ "${1}" = "col" ]; then
          lines=$(expr `grep -n "Normal termination" $i/1.out |awk -F: '{print $1}' |tail -1` - `grep -n "/l9999.exe" $i/1.out |awk -F: '{print $1}' |tail -1`)
          scf=`egrep "Done|xtrapolated" $i/1.out | tail -n 1 | awk '{print "="$3" ="$5}'` 
          energies=`grep 'Sum of e' $i/1.out | awk ' {if ($5=="zero-point") {zpe=$7} if ($6=="Energies=") {te=$7} if ($6=="Enthalpies=") {tH=$7} if ($6=="Free") {tG=$8}} {print "="zpe, "="te, "="tH, "="tG} ' |tail -1`
          nbasis=`grep NBasis $i/1.out | tail -n 1 | awk '{print "="$2}'`
# awk will also work
#          nimag=`grep -A5 "PG=" $i/1.out  | tr '\n' ' '  |sed 's%  %%g' | awk -F'\' '/NImag/ {for (i=1; i<=NF; i++) print $i;}' | grep "NImag"`
# sed with '' will also work!
#          nimag=`tail -$lines $i/1.out  |tr '\n' ' ' |sed 's%  %%g' |sed 's:\\\:\n:g' |grep "NImag"`
#          nimag=`tail -$lines $i/1.out  |tr '\n' ' ' |sed 's%  %%g' |sed 's%\\\%\n%g' |grep "NImag"`
# should work, but does not!
#          nimag=`tail -$lines $i/1.out  |tr '\n' ' ' |sed 's%  %%g' |sed 's%\\%\n%g' |grep "NImag"`
# sed with "" will not work!
#          nimag=`tail -$lines $i/1.out  |tr '\n' ' ' |sed 's%  %%g' |sed "s%\\\%\n%g" |grep "NImag"`
          nimag="=`tail -$lines $i/1.out  |tr '\\n' ' ' |sed 's%  %%g' |tr '\\\' '\\n' |grep "NImag"`"
          echo `pwd`/$j $scf $energies $nbasis $nimag
         fi

       elif [ "${1}" != "col" ]; then

# if this was a kjob, write the file with the appropriate number of lines of filler
       for (( c=1; c<=7; c++ ))
        do
        echo "***a %KJOB run***"
        done
       fi

      elif [ "${1}" != "col" ]; then

# if the job failed, write the file with the appropriate number of lines of filler
       for (( c=1; c<=7; c++ ))
        do
        echo "***the job failed***"
        done
      fi
      if [ "${1}" != "col" ]; then
#      echo " "
      printf '\n'
      fi
    fi

# separate the records with a space and hard return
  done

if [ -z "$anyoutput" ]; then
 echo there were no output files!
fi
