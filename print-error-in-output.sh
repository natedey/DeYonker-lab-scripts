#!/bin/bash
# CEW 10/22/2013
# usage:
#
# print-error-in-output.sh (arg1)
#
## the script will help find specfic error in GXX output files

debug=0
script_name=print-error-in-output

if [ "$1" = "--help" ]; then
echo "This script extracts the number of optimization steps from an output GXX file
$script_name.sh (filename)

$script_name.sh (arg1)
if no arg1 is given, all 1.out files are searched

arg1 can be a single file

if arg1 is \"-f\", then arg2 must be a string to use in a find command
this string must be in quotes  or it must be properly escaped
e.g.,

$script_name.sh -f \"1-fail?\"
OR
$script_name.sh -f 1-fail\?
will search all 1-fail? files

$script_name.sh -f \"*\"
OR
$script_name.sh -f \*
will search all files
"
exit
fi

if [ -z "$1" ]; then
 echo "processing all 1.out files in all subdirectories"

files=(`find ./ -type f -name 1.out`)

elif [ -n "$1" ] && [ "$1" == "-f" ]; then
 if [ -z "$2" ]; then
  echo you need a second command line argument to use in the find command
  exit
 fi
# what=`echo $2|sed s%\*%\\\*%g`
# echo what is $what
 echo "searching for \"$2\" files to process"
 files=(`find ./ -type f -name "$2"`)

elif [ -n "$1" ] && [ -f "$1" ]; then
 echo "processing $1 file"
 files="$1"
else
 echo it appears that your combination of args did not find anything to do
 exit
fi


 for (( i = 0 ; i < ${#files[*]} ; i++ ))
 do

# if not a gaussian file, don't process it
isoutputfile=`head -1 ${files[i]} | cut -f1 -d,`
if [ "$isoutputfile" == " Entering Gaussian System" ]; then

 if [ "`tail -1 ${files[i]} |awk '{print $1, $2}'`" == "Normal termination" ]; then
  completion="completed:"

  if [ -n "`grep Warning:\ \ center ${files[i]}`" ]; then
   basis_set_error=1
  fi

 else
  completion="failed:"

  if [ -n "`grep Warning:\ \ center ${files[i]}`" ]; then
   basis_set_error=1
  else
   basis_set_error=0
  fi

# could generalize this script with this:
version="`grep -A1 " Cite this work as:" ${files[i]} |head -2| grep -v Cite |\
sed 's%Gaussian 09, Revision D.01%g09d01%g' |\
sed 's%Gaussian 09, Revision C.01%g09c01%g' |\
sed 's%Gaussian 09, Revision B.01%g09b01%g' |\
sed 's%Gaussian 09, Revision A.02%g09a02%g' |\
sed 's%Gaussian 03, Revision C.02%g03c02%g'`"

  nsteps=`grep "Step number" ${files[i]} | grep -v "Step number   1 out of a maximum of    2" |tail -1 |awk '{print $3}'`
  if [ -z "$nsteps" ]; then
   nsteps=none
  fi

  error="`egrep "Error|\
Charge and multiplicity card seems defective|\
The combination of multiplicity|\
Invalid extra data found|\
EOF while reading ECP pointer card|\
Atomic number out of range for|\
WANTED A STRING AS INPUT.|\
Problem with the distance matrix.|\
Atoms too close.|\
Linear angle in Bend|\
Linear angle in Tors.|\
Inconsistency:|\
No acceptable step|\
Number of steps exceeded,  NStep|\
Convergence failure -- run terminated|\
Convergence failure|\
Consistency failure|\
FormBX had a problem|\
You need to solve for more vectors in order to follow this state|\
Requested step has not been saved.|\
A syntax error was detected in the input line|\
Inaccurate quadrature in CalDSu|\
Rerun with SCF=IntRep|\
atoms found in this molecule.|\
unrecognized in AtmBas|\
No data on chk file.|\
RedCar/ORedCr failed for GTrans.|\
In source file ml0.f"\
  ${files[i]}\
  | egrep -v "RMS Error=|Error on total polarization charges|Error termination via Lnk1e|Error: segmentation violation|Error termination request processed by link 9999"`"

#  | egrep -v "Error termination via Lnk1e|Error: segmentation violation|Error termination request processed by link 9999"`"
#Consistency failure|\ \#1 in FindCO."\

  number=`grep -c "Error: software termination" ${files[i]}`
  if [ $(($number)) -gt 1 ]; then
   error="Error: software termination"
  fi

  write_number=`grep -c "Erroneous write. Write" ${files[i]}`
  if [ $(($write_number)) -gt 1 ]; then
   error="Erroneous write. Write"
  fi

  write_number=`grep -c "Erroneous read. Read" ${files[i]}`
  if [ $(($write_number)) -gt 1 ]; then
   error="Erroneous read. Read"
  fi

  if [ -z "$error" ]; then
   segmentation=`grep -c "Error: segmentation violation" ${files[i]}`
   if [ $(($segmentation)) -eq 1 ]; then
    error="Error: segmentation violation"
   fi
  fi

  still_going="`egrep -v Error ${files[i]}`"

  if [ -n "$error" ]; then
   printf "%s at step: %3s GXX.version: %s with %s for %s\n" "$completion" "$nsteps" "$version" "$error" ${files[i]}
  elif [ "$basis_set_error" == 1 ]; then
   basis_set_error="missing basis functions"
   printf "%s at step: %3s GXX.version: %s with %s for %s\n" "$completion" "$nsteps" "$version" "$basis_set_error" ${files[i]}
  elif [ -n "$still_going" ]; then
   printf "middle: at step: %3s GXX.version: %s for %s\n" "$nsteps" "$version" ${files[i]}
  else
   printf "%s at step: %3s GXX.version: %s with another error for %s\n" "$completion" "$nsteps" "$version" ${files[i]}
  fi

 fi

 if [ "$completion" != "failed:" ]; then
  if [ "$basis_set_error" == 1 ]; then
    basis_set_error="missing basis functions"
    printf "%s at step: %3s GXX.version: %s with %s for %s\n" "$completion" "$nsteps" "$version" "$basis_set_error" ${files[i]}
  fi
 fi

else
 if [ $debug == "1" ]; then
  echo ${files[i]} is not a Gaussian output file
 fi
 other_error="`grep 'In source file ml0.f' ${files[i]}`"
 if [ -n "$other_error" ]; then
  echo ${files[i]} has a write issue, maybe check the node for /scratch or /tmp
 fi
fi

 done


# Consistency failure #1 in FindCO.  <-- you probably left off an ECP or basis set/ECP
