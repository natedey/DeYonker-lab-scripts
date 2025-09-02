#!/bin/bash
# CEW

if [ "$1" = "--help" ]; then
echo "This script extracts the geometry in coords (format for input to msi) from opt+freq output GXX file
extract-coords.sh filename
"
exit
fi

if [ -z "$1" ] && [ -f 1.out ]; then
 file=1.out
elif [ -n "$1" ] && [ ! -f "$1" ]; then
 echo "$1" file does not exist
 exit
elif [ -f "$1" ]; then
 isoutputfile=`head -1 "$1" | cut -f1 -d,`
 if [ "$isoutputfile" != " Entering Gaussian System" ]; then
  echo "$1" is not a Gaussian output file
  exit
 fi
 file="$1"
else
 echo you need a filename as the first command-line argument
 exit
fi

#natoms=$(expr `grep -i NAtoms $file | head -n 1 | awk ' {print $2} '`)
natoms=$((`grep -i NAtoms $file | head -n 1 | awk ' {print $2} '`))
 if [ "$natoms" -eq 0 ]; then
 # echo the number of atoms is empty, trying again...
  natoms=$((`grep "Using compressed storage, NAtomX" $file | head -n 1 | awk ' {print $5} ' |sed 's%.$%%g'`))
  if [ "$natoms" -eq 0 ]; then
   echo the number of atoms is still empty
   exit
  fi
 fi
nlines=$(($natoms + 5))

isnormaloutputfile=`tail -1 $file |awk '{print $1, $2}'`
if [ "$isnormaloutputfile" != "Normal termination" ]; then
 echo $file failed to terminate properly
 exit
fi

jobsteps=`grep -c "Normal termination" $file`
if [ $jobsteps -lt 1 ]; then
 echo $file did not terminate properly
 exit
fi

stdorientation=`grep -c "Standard orientation:" $file`
inputorientation=`grep -c "Input orientation:" $file`
if [ "$stdorientation" -eq "0" ] && [ "$inputorientation" -eq "0" ]; then
 orientation=Z-Matrix
elif [ "$stdorientation" -eq "0" ]; then
 orientation=Input
else
 orientation=Standard
fi

echo $natoms

#if [ $jobsteps == "2" ]; then
if [ $jobsteps -ge "2" ]; then
 firststepln=`grep -n "Normal termination" $file | head -1 | cut -f1 -d:`
  laststepln=`grep -n "Normal termination" $file | tail -1 | cut -f1 -d:`
  file_lines=$(( $laststepln - $firststepln ))
 tail -$file_lines $file | grep -A $(($nlines-1)) "$orientation orientation:" |tail -n $natoms
elif [ $jobsteps == "1" ]; then
 grep -A $(($nlines-1)) "$orientation orientation:" $file |tail -n $natoms
fi
