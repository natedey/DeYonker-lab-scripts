#!/bin/bash
# script to set up full ts opts for CM MD->QM project
# created DAW Jan 2026
# usage: cmsetup-tsopt.sh [list file]

wkdr=$(pwd)
joblist="none"
for i in $(cat $1); do
  d=$(echo $i | awk -F/ '{print $1}')
  echo $d
  cd $d
  mkdir tsopt
  cp tsconstrained/orca.hess tsopt/tsconstrained.hess
  cd tsopt
  replace_orca_inp_geom.py -inp ../tsconstrained/orca.inp -xyz ../tsconstrained/orca.xyz -tsopt -inhess tsconstrained.hess
  sed -i "/Calc_Hess/d; /Recalc_Hess/d" orca.inp
  if [[ "$joblist" == "none" ]]; then
    joblist=$((10#${d#f}))
  else
    joblist=$joblist","$((10#${d#f}))
  fi
  cd $wkdr
done

cp ~/git/DeYonker-lab-scripts/dwappett/1-array-tsopt 1-array-tsopt
sed -i "s/ASTART-AEND\%4/${joblist}%1/" 1-array-tsopt
