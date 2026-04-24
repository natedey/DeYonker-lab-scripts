#!/bin/bash

# DAW 2026-04-22
# script for copying over completed models' outputs from DAW's skipped ahead dirs

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
 echo "this script fills in dirs that Domi has already completed so you aren't duplicating calculations"
 echo "to be run after setting up new models before starting calculations"
 exit
fi

if [[ "$(pwd)" == *"QM-A"* ]]; then
 donedirs="/project/dwappett/chorismate_mutase/QM-ind-models-every-100th/A128-f05100-f20000"
elif [[ "$(pwd)" == *"QM-B"* ]]; then
 donedirs="/project/dwappett/chorismate_mutase/QM-ind-models-every-100th/B256-f05100-f20000"
elif [[ "$(pwd)" == *"QM-C"* ]]; then
 donedirs="/project/dwappett/chorismate_mutase/QM-ind-models-every-100th/C384-f05100-f20000"
else
 echo "can't recognise active site from pwd!"
 exit
fi

joblist="none"
for i in $(ls -d f*); do
 if [ -d $donedirs/$i ]; then
  # remove existing directory first just so there's no chance of file clashes with changed inps/double rinrus log files/etc
  rm -r $i
  cp -r $donedirs/$i .
  echo "filled in dir $i"
 else
  # log model numbers for jobs that do need to be started
  if [[ "$joblist" == "none" ]]; then
   joblist=$((10#${i#f}))
  else
   joblist=$joblist","$((10#${i#f}))
  fi
 fi
done

echo "before submitting 1-array, please replace array list with this corrected list!"
echo "$joblist"
