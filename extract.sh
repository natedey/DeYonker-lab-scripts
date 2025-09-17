#!/bin/bash
# original: CEW 10/19/2011
# DAW modified 2025
# usage:
# extract.sh [args]
# the script will extract the computed energies and other information for gaussian out files

if [ "$1" == *"-h"* ]; then
echo "This script extracts the following info from gaussian outputs:
1) output file path
2) functional (not printed for xtb)
3) E elect
4) Eo
5) E + thrm E
6) H
7) G
8) no. basis functions (not printed for xtb)
9) no. imag freqs

If the job is not an optimization, the script will print just the energy
and number of basis functions.

Extracts from all 1.out files in dir and subdirs by default.
Other options:
extract.sh list [list file]  -to extract from 1.out in each dir listed in file
extract.sh [file(s)]  -to extract from specific file(s) (needs to be file name not directory)
"
exit
fi

if [ -z $1 ] || [[ "$1" == "list" ]]; then
 # if no argument, get current dir and its subdirs
 if [ -z $1 ]; then
  directories=( `find ./ -type d` )
 # if arg1 is list, then get list of dirs from list file
 elif [[ "$1" == "list" ]]; then
  directories=( $(cat $2) )
 fi
 for i in "${directories[@]}"; do
# clean up the name of the directory to remove "./" from the name
   j=$(echo $i|sed 's%\.\/%%g')
# make sure the 1.out file exists
   if test -s $i/1.out; then
    anyoutput=1
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
      lines=$(expr `grep -na "Normal termination" $i/1.out |awk -F: '{print $1}' |tail -1` - `grep -na "/l9999.exe" $i/1.out |awk -F: '{print $1}' |tail -1`)
      if grep -q "xtb-gaussian" $i/1.out; then
       ### DAW NOTE 09-2025: current version matched to how I set up my spreadsheets where dft and xtb have diff no. columns
       ### if you want xtb and dft extracted output to have consistent columns then reverse which of these lines are commented out
       ### also needs to be changed below
       scf=$(grep -a "Recovered energy=" $i/1.out | tail -1 | awk '{print "="$3}')
       nbasis=""
       #scf=$(grep -a "Recovered energy=" $i/1.out | tail -1 | awk '{print "xtb ="$3}')
       #nbasis="NA"
      else
       scf=`egrep -a " Done|xtrapolated" $i/1.out | tail -n 1 | awk '{print $3" ="$5}'` 
       nbasis=`grep -a NBasis $i/1.out | tail -n 1 | awk '{print "="$2}'`
      fi
      energies=`grep -a 'Sum of e' $i/1.out | awk ' {if ($5=="zero-point") {zpe=$7} if ($6=="Energies=") {te=$7} if ($6=="Enthalpies=") {tH=$7} if ($6=="Free") {tG=$8}} {print "="zpe, "="te, "="tH, "="tG} ' |tail -1`
      nimag="`tail -$lines $i/1.out  |tr '\\n' ' ' |sed 's%  %%g' |tr '\\\' '\\n' |grep "NImag"`"
      echo `pwd`/$j $scf $energies $nbasis $nimag
     fi
    fi
   fi
 done
else
 for i in "$@"; do
   j=$(echo $i|sed 's%\.\/%%g')
   if test -s $i; then
    anyoutput=1
    #echo `pwd`/$j
    if [ "`tail -n 1 $i |awk '{print $1, $2}'`" = "Normal termination" ]; then
     if [ ! -n `tail -n 6 $i |head -n 1 |awk '{print $1}'` ]; then
      STR="dummy variable"
     else
      STR=`tail -n 6 $i | head -n 1 |awk '{print $1}'`
     fi
     
     if [ ${STR:-0} != "*Kjob" ]; then
      lines=$(expr `grep -na "Normal termination" $i |awk -F: '{print $1}' |tail -1` - `grep -na "/l9999.exe" $i |awk -F: '{print $1}' |tail -1`)
      if grep -q "xtb-gaussian" $i; then
       ### DAW NOTE 09-2025: current version matched to how I set up my spreadsheets where dft and xtb have diff no. columns
       ### if you want xtb and dft extracted output to have consistent columns then reverse which of these lines are commented out
       ### also needs to be changed above
       scf=$(grep -a "Recovered energy=" $i | tail -1 | awk '{print "="$3}')
       nbasis=""
       #scf=$(grep -a "Recovered energy=" $i | tail -1 | awk '{print "xtb ="$3}')
       #nbasis="NA"
      else
       scf=`egrep -a "Done|xtrapolated" $i | tail -n 1 | awk '{print $3" ="$5}'`
      fi
      energies=`grep -a 'Sum of e' $i | awk ' {if ($5=="zero-point") {zpe=$7} if ($6=="Energies=") {te=$7} if ($6=="Enthalpies=") {tH=$7} if ($6=="Free") {tG=$8}} {print "="zpe, "="te, "="tH, "="tG} ' |tail -1`
      nbasis=`grep -a NBasis $i | tail -n 1 | awk '{print "="$2}'`
      nimag="`tail -$lines $i  |tr '\\n' ' ' |sed 's%  %%g' |tr '\\\' '\\n' |grep "NImag"`"
      echo `pwd`/$j $scf $energies $nbasis $nimag
     fi
    fi
   fi
 done
fi

if [ -z "$anyoutput" ]; then
 echo there were no output files!
fi
