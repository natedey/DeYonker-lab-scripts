#!/bin/bash
# script to set up ts guesses/constrained opts for CM MD->QM project
# created DAW Jan 2026
# usage: cmsetup-tsconstrained.sh [list file]
# only sets up dirs/jobs if tsconstrained dir doesn't exist yet so stuff isn't overwritten

wkdr=$(pwd)
joblist="none"
for i in $(cat $1); do
  cd $i
  if [ ! -d "tsconstrained" ]; then
    xyz_to_pdb.py -pdb model_*_template.pdb -name ${i}-opt
    mkdir tsconstrained
    cd tsconstrained
    cm-tsguess-orcaxtb.sh ../${i}-opt.pdb
    if [[ "$joblist" == "none" ]]; then
      joblist=$((10#${i#f}))
    else
      joblist=$joblist","$((10#${i#f}))
    fi
  fi
  cd $wkdr
done

cp ~/git/DeYonker-lab-scripts/dwappett/1-array-tsconstrained 1-array-tsconstrained
sed -i "s/ASTART-AEND\%4/${joblist}%10/" 1-array-tsconstrained
