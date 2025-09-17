#!/bin/bash

# DAW 2025-09-17
# populate-submission-scripts.sh
# adds "1" file to all subdirectories that do not already have one
# uses gen_orca6_jobscript and gen_g16_jobscript to match to present input file
# currently can't do 

directories=( `find ./ -type d | sort` )
echo "$directories"

for d in "${directories[@]}"; do
 if [[ "$d" == "." ]]; then
  continue
 elif [ -f $d/1 ]; then 
  echo "Directory $d already has 1 file. Skipping"
  continue
 else
  cd $d
  # find input files excluding rinrus driver inp
  if [[ $(find . -name "*.inp" | grep -v "rinrus.inp" | wc -l) == 0 ]]; then
   if [ -f input.dat ]; then
    $(dirname "$0")/gen_jobscript_psi4.sh
    echo "Created psi4 1 file for directory $d"
   else
    echo "Directory $d has no input file. Skipping"
   fi
  elif [[ $(find . -name "*.inp" | grep -v "rinrus.inp" | wc -l) -gt 1 ]]; then
   echo "Directory $d has more than one input file. Skipping"
  else
   inpf=$(find . -name "*.inp" | grep -v "rinrus.inp" | sed "s#./##")
   if [[ "$(head -1 $inpf)" == *"chk"* ]]; then
    $(dirname "$0")/gen_jobscript_g16.sh
    echo "Created g16 1 file for directory $d"
   elif [[ "$(head -1 $inpf)" == "!"* ]]; then
    $(dirname "$0")/gen_jobscript_orca6.sh $inpf
    echo "Created orca 1 file for directory $d"
   else
    echo "Input file in directory $d doesn't seem to be for g16, orca or psi4. Skipping"
   fi
  fi
  cd ..
 fi
done

