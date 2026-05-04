#!/bin/bash

# redo direct tsopts for stuff currently excluded!

todaysyear=$(date '+%Y')
todaysmonth=$(date '+%m')
if [[ $todaysyear -gt 2026 ]] || [[ $todaysmonth -gt 5 ]]; then
  echo "this script helps you redo direct tsopts where the input did not have the calc_hess keyword"
  echo "this only needs to be done for models where the direct tsopt was set up BEFORE the setup script was fixed (april 22 2026)"
  echo "are you sure you still need to be using this now? enter y to continue or anything else to exit"
  read altlist
  if [[ "${altlist,,}" == "y" ]]; then
    echo "continuing"
  else
    exit
  fi
fi 

for i in $(ls -d f*); do
 if [ -f $i/tsopt/altts-directopt.txt ]; then
  if grep -q "Calc_Hess true" $i/tsopt/orca.inp; then
   echo "$i direct tsopt already has calc_hess on, skipping"
  else
   echo "redoing $i direct tsopt setup"
   echo "$i" >> check_tsopt_redoalldirectopts.txt
   cd $i
   # rename existing directopt attempt to bad-directopt
   mv tsopt tsopt-bad-directopt
   # move previous tsopt attempt back to tsopt (setup script will move it back to tsopt-failed, just easier to not have to change how that is handled)
   mv tsopt-failed tsopt
   cd ..
  fi
 fi
done

### old code that only restarted failed ones, not everything ###
#for i in $(awk '{print $1}' check_tsopt_excluded.txt); do
#  d=$(echo $i | awk -F/ '{print $1}')
#  if grep -q -i "exclude" <<< $(grep $d check_tsopt_excluded.txt); then
#    echo "$d - seems to be manually excluded so skipping"
#    sed -i "\#$d#d" check_tsopt_excluded.txt
#  elif grep -q "Calc_Hess true" $d/tsopt/orca.inp; then
#    echo "$d - tsopt/orca.inp already has Calc_Hess true so skipping"
#    sed -i "\#$d#d" check_tsopt_excluded.txt
#  else
#    echo $d
#    cd $d
#    # rename existing directopt attempt to bad-directopt
#    mv tsopt tsopt-bad-directopt
#    # move previous tsopt attempt back to tsopt (setup script will move it back to tsopt-failed, just easier to not have to change how that is handled)
#    mv tsopt-failed tsopt
#    cd ..
#  fi
#done

echo "now re-running cmsetup-direct-tsopt.sh"
#yes Y | cmsetup-direct-tsopt.sh check_tsopt_excluded.txt
yes Y | cmsetup-direct-tsopt.sh check_tsopt_redoalldirectopts.txt
