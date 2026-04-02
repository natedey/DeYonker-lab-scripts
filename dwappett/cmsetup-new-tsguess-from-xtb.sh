#!/bin/bash
# script to set up alternative ts guesses/constrained opts for CM MD->QM project
# created DAW Feb 2026
# usage: cmsetup-tsconstrained.sh [list file]
# only sets up dirs/jobs if tsconstrained dir doesn't exist yet so stuff isn't overwritten

if [ -z "$1" ]; then
  echo "this script needs a list file!"
  exit
elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  echo "
usage: cmsetup-new-tsguess-from-xtb.sh [list]
sets up a ts guess and constrained opt like cmsetup-tsconstrained.sh but uses your active site's f00001 xtb ts instead of the old xtal ts.
the old tsconstrained/tsopt(/tsopt-failed if tried) subdirectories will be renamed as original-tsguess-[subdir] for clarity.

this directories in the list given to this script:
  a) must have failed with the standard procedure
  b) must NOT have already had a new guess set up with this script or otherwise

the automated check_tsopt_[not-done].txt lists do not distinguish whether a tsopt is currently stuck at the normal first try/new guess/direct tsopt
and this script does not skip already set up directories like the original cmsetup-tsconstrained does!!!
to be safe, please prepare the list BY HAND! 
"
  exit
elif grep -q -e 'initialopt' -e 'irc1' -e 'irc2' <<< $1; then
  echo "you should not be trying to use this script with an initialopt/irc1/irc2 list!"
  exit
elif [[ "$1" == "check_tsopt_"* || "$1" == "check_tsconstrained_"* ]]; then
  echo "
  looks like you've provided one of the standard automated check_cm_jobs.sh output lists which is not recommended.
  those lists do not distinguish whether a tsopt is currently stuck at the normal first try/new guess/direct tsopt
  and this script does not skip already set up directories like the original cmsetup-tsconstrained does!!!
  this directories in the list given to this script:
    a) must have failed with the standard procedure
    b) must NOT have already had a new guess set up with this script or otherwise
  if you are not 100% confident that everything in this list meets those criteria, press enter to cancel
  otherwise enter Y to continue with list $1"
  read altlist
  if [[ "${altlist,,}" == "y" ]]; then
    echo "continuing with list $1"
  else
    exit
  fi
fi

### get old ts to fit in to make guess ###
if grep -q "QM-A" <<< $(pwd) || grep -q "A128" <<< $(pwd); then
  tsforfitting='~/git/DeYonker-lab-scripts/dwappett/f00001-A128-ts-opt.pdb'
  tslabel='f00001-A128'
elif grep -q "QM-B" <<< $(pwd) || grep -q "B256" <<< $(pwd); then
  tsforfitting='~/git/DeYonker-lab-scripts/dwappett/f00001-B256-ts-opt.pdb'
  tslabel='f00001-B256'
elif grep -q "QM-C" <<< $(pwd) || grep -q "C384" <<< $(pwd); then
  tsforfitting='~/git/DeYonker-lab-scripts/dwappett/f00001-C384-ts-opt.pdb'
  tslabel='f00001-C384'
else
  echo "can't determine active site from current directory name! please enter absolute path to optimised ts pdb file to fit"
  read tsforfitting
  tslabel=$(echo $tsforfitting | awk -F/ '{print $NF}' | sed "s/.pdb//")
fi

wkdr=$(pwd)
joblist="none"
for d in $(awk '{print $1}' $1); do
  # make sure we're just working with frame name not tsopt subdir or w/e
  i=$(echo $d | awk -F/ '{print $1}')
  echo $i
  # remove from existing status lists!! in case you try to start other jobs before running check_cm_jobs again
  for j in "done" "tsmodegone" "CHECK_MANUALLY"; do
   if [ -f "check_tsconstrained_${j}.txt" ]; then sed -i "\#$i#d" check_tsconstrained_${j}.txt; fi
   if [ -f "check_tsopt_${j}.txt" ]; then sed -i "\#$i#d" check_tsopt_${j}.txt; fi
  done
  cd $i
  # move existing directories to make it clear what is happening
  for j in $(ls -d tsconstrained* tsopt*); do
    mv $j original-tsguess-$j
  done
  # start fresh dir
  mkdir tsconstrained
  cd tsconstrained
  # create new guess and label for clarity
  align_TSA_and_replace.py -modpdb ../${i}-opt.pdb -md -tspdb $tsforfitting -newpdb old_TS_aligned.${tslabel}.pdb
  # create input file
  write_input.py -pdb tsguess.pdb -format orca -intmp ~/git/DeYonker-lab-scripts/dwappett/orcaxtb_intmp.txt -c -2 -inpn orca.inp
  bond1a=$(( $(awk '$4 == "COR" && $3 == "C1" {print $2}' tsguess.pdb) - 1 ))
  bond1b=$(( $(awk '$4 == "COR" && $3 == "C9" {print $2}' tsguess.pdb) - 1 ))
  bond2a=$(( $(awk '$4 == "COR" && $3 == "C5" {print $2}' tsguess.pdb) - 1 ))
  bond2b=$(( $(awk '$4 == "COR" && $3 == "O7" {print $2}' tsguess.pdb) - 1 ))
  sed -i "s/constraints/constraints\n  { B $bond1a $bond1b C }  #product bond\n  { B $bond2a $bond2b C }  #reactant bond/" orca.inp
  if [[ "$joblist" == "none" ]]; then
    joblist=$((10#${i#f}))
  else
    joblist=$joblist","$((10#${i#f}))
  fi
  touch "altts-newguess.txt"
  cd $wkdr
done

cp ~/git/DeYonker-lab-scripts/dwappett/1-array-tsconstrained 1-array-tsconstrained-newguess
sed -i "s/ASTART-AEND\%1/${joblist}%4/" 1-array-tsconstrained-newguess

echo ""
echo "created 1-array-tsconstrained-newguess"


