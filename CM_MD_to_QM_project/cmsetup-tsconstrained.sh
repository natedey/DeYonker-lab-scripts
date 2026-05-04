#!/bin/bash
# script to set up ts guesses/constrained opts for CM MD->QM project
# created DAW Jan 2026
# usage: cmsetup-tsconstrained.sh [list file]
# only sets up dirs/jobs if tsconstrained dir doesn't exist yet so stuff isn't overwritten

if [ -z "$1" ]; then
  set check_initialopt_done.txt
  echo "using default list: $1"
elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  echo "usage: cmsetup-tsconstrained.sh check_initialopt_done.txt
sets up a ts guess structure and prepares an input for the constrained opt
script will skip fxxxxx dirs which already have a tsconstrained subdir!"
  exit
elif [[ "$1" != "check_initialopt_done.txt" ]]; then
  echo "this script is designed to be used with the check_initialopt_done.txt list which is not what was provided
are you sure you want to continue with list $1? [Y/N]"
  read altlist
  if [[ "${altlist,,}" == "y" ]]; then
    echo "continuing with list $1"
  else
    echo "quitting"
    exit
  fi
fi

wkdr=$(pwd)
joblist="none"
for i in $(cat $1); do
  cd $i
  if [ ! -d "tsconstrained" ]; then
    echo $i
    xyz_to_pdb.py -pdb model_*_template.pdb -name ${i}-opt
    mkdir tsconstrained
    cd tsconstrained
    cm-tsguess-orcaxtb.sh ../${i}-opt.pdb
    if [[ "$joblist" == "none" ]]; then
      joblist=$((10#${i#f}))
    else
      joblist=$joblist","$((10#${i#f}))
    fi
  else
    echo "$i - skipping because tsconstrained already set up"
  fi
  cd $wkdr
done

cp ~/git/DeYonker-lab-scripts/CM_MD_to_QM_project/1-array-tsconstrained 1-array-tsconstrained
sed -i "s/ASTART-AEND\%1/${joblist}%4/" 1-array-tsconstrained

echo ""
echo "created 1-array-tsconstrained"
