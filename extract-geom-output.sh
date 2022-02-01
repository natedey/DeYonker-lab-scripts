#!/bin/bash
# CEW

if [ "$1" = "--help" ]; then
echo "This script extracts the geometry for a given step in output format for input to msi
extract-geom-output.sh step-number filename
"
exit
fi

if [ -z "$1" ]; then
 echo you need to enter a step number or energy
 exit
else

  if [ -z "$2" ] && [ -f 1.out ]; then
   file=1.out
  elif [ -n "$2" ] && [ ! -f "$2" ]; then
   echo "$2" file does not exist
   exit
  elif [ -f "$2" ]; then
   isoutputfile=`head -1 "$2" | cut -f1 -d,`
   if [ "$isoutputfile" != " Entering Gaussian System" ]; then
    echo "$2" is not a Gaussian output file
    exit
   fi
   file="$2"
  else
   echo you need a filename as the second command-line argument
   exit
  fi
fi

 isoniomoutputfile=`grep "ONIOM: extrapolated" "$file" | head -1`

 if [ -n "$isoniomoutputfile" ]; then
  energy="extrapolated"
 else
  energy="SCF Done"
 fi

 number_D="`grep -c "Numerically estimating second derivatives" $file`"
  if [ $number_D -eq 0 ]; then
    number_D=0
  fi

 stepnumber=$1

 valid_step="`echo $stepnumber | egrep ^[[:digit:]]+$`"

 if [ "$stepnumber" == "0" ]; then
   echo arg1: $stepnumber\; first command line argument needs to be first, last, a whole number, or an energy to be valid
   exit
 elif [ "$stepnumber" != "first" ] && [ "$stepnumber" != "last" ] && [ "$valid_step" = "" ]; then
  if [ -z "`grep "$energy" $file | grep -- $stepnumber`" ]; then
   echo arg1: $stepnumber\; first command line argument needs to be first, last, a whole number, or an energy to be valid
   exit
  fi
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

jobsteps=`grep -c "Normal termination" $file`
stdorientation=`grep -c "Standard orientation:" $file`

if [ "$stdorientation" -eq "0" ];then
 orientation=Input
else
 orientation=Standard
fi

if [ $jobsteps == "2" ]; then
 firststepln=`grep -n "Normal termination" $file | head -1 | cut -f1 -d:`
 totalnumbersteps=$((`grep -c "Step number" $file`-1))
 if [ -n "$valid_step" ]; then
# orientationln=(`grep -n "$orientation orientation:" $file | cut -f1 -d:`)
 orientationln=(`grep -n "$orientation orientation:" $file | awk 'NR>'"$number_D"'{print}'| cut -f1 -d:`)
  stepnumberln=(`grep -n "Step number" $file | cut -f1 -d:`)
  if [ "$stepnumber" != "first" ] && [ "$stepnumber" != "last" ]; then
   if [ "$stepnumber" -gt "$totalnumbersteps" ]; then
    echo you requested a step that does not exist
    echo there are only $totalnumbersteps steps in $file
    exit
   fi
  fi
 else
 orientationln=(`egrep -n "$energy|orientation:" $file | grep -B1 -- "$stepnumber" | grep "orientation:" | cut -f1 -d:`)
  stepnumberln=(`grep -n -- "$stepnumber" $file |head -1 | cut -f1 -d:`)
 fi


elif [ $jobsteps == "1" ] || [ $jobsteps == "0" ]; then
 firststepln=`grep -n "Normal termination" $file | head -1 | cut -f1 -d:`
 totalnumbersteps=$((`grep -c "Step number" $file`))
 if [ -n "$valid_step" ]; then
# orientationln=(`grep -n "$orientation orientation:" $file | cut -f1 -d:`)
 orientationln=(`grep -n "$orientation orientation:" $file | awk 'NR>'"$number_D"'{print}'| cut -f1 -d:`)
  stepnumberln=(`grep -n "Step number" $file | cut -f1 -d:`)
  if [ "$stepnumber" != "first" ] && [ "$stepnumber" != "last" ]; then
   if [ "$stepnumber" -gt "$totalnumbersteps" ]; then
    echo you requested a step that does not exist
    echo there are only $totalnumbersteps steps in $file
    exit
   fi
  fi
 else
 orientationln=(`egrep -n "$energy|orientation:" $file | grep -B1 -- "$stepnumber" | grep "orientation:" | cut -f1 -d:`)
  stepnumberln=(`grep -n -- "$stepnumber" $file |head -1 | cut -f1 -d:`)
 fi

else
 echo $file has too many linked jobs, are you sure this is an opt or opt+freq?
exit
fi

# get the part of the output file that you need and then trim the output
#awk "NR==1346,NR==1541" $file |head -$nlines |tail -$natoms
echo $natoms
if [ "$stepnumber" == "first" ]; then
  grep -A $nlines "$orientation orientation:" $file |head -n $nlines |tail -n $natoms
  echo "# first step from $file"
elif [ "$stepnumber" == "last" ]; then
  grep -A $(($nlines-1)) "$orientation orientation:" $file |tail -n $natoms
  echo "# last step from $file"
elif [ -n "$valid_step" ]; then
   if [ "${stepnumberln[$((stepnumber-1))]}" == "" ]; then
    last_line=last
   fi
    last_line=${stepnumberln[$((stepnumber-1))]}
#  awk 'NR=='"${orientationln[$((stepnumber))]}"',NR=='"${stepnumberln[$((stepnumber))]}"'' $file |head -$nlines |tail -$natoms
  awk 'NR=='"${orientationln[$((stepnumber-1))]}"',NR=='"$last_line"'' $file |head -$nlines |tail -$natoms
  echo "# step number $stepnumber from $file"
else
  awk 'NR=='"$orientationln"',NR=='"$stepnumberln"'' $file |head -$nlines |tail -$natoms
  echo "# energy $stepnumber from $file"
fi
