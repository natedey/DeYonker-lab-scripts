#!/bin/bash
# script to set up full ts opts for CM MD->QM project
# created DAW Jan 2026
# usage: cmsetup-tsopt.sh [list file]

if [ -z "$1" ]; then
  set check_tsconstrained_done.txt
  echo "using default list: check_tsconstrained_done.txt"
elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  echo "usage: cmsetup-tsopt.sh check_tsconstrained_done.txt
uses the tsconstrained orca.xyz and orca.hess files to set up a full ts optimisation
script will skip fxxxxx dirs which already have a tsopt subdir!"
  exit
elif [[ "$1" != "check_tsconstrained_done.txt" ]]; then
  echo "this script is designed to be used with the check_tsconstrained_done.txt list which is not what was provided
are you sure you want to continue with list $1? [Y/N]"
  read altlist
  if [[ "${altlist,,}" == "y" ]]; then
    echo "continuing with list $1"
  else
    exit
  fi
fi

wkdr=$(pwd)
joblist="none"
for i in $(cat $1); do
  d=$(echo $i | awk -F/ '{print $1}')
  cd $d
  if [ ! -d "tsopt" ]; then
    echo $d
    mkdir tsopt
    cp tsconstrained/orca.hess tsopt/tsconstrained.hess
    cd tsopt
    replace_orca_inp_geom.py -inp ../tsconstrained/orca.inp -xyz ../tsconstrained/orca.xyz -tsopt -inhess tsconstrained.hess
    sed -i "/Calc_Hess/d; /Recalc_Hess/d" orca.inp
    if grep -q "product bond" ../tsconstrained/orca.inp && grep -q "reactant bond" ../tsconstrained/orca.inp; then
      b1=$(grep "product bond" ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
      b2=$(grep "reactant bond" ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
      sed -i "s/%geom/%geom\n  modify_internal\n$b1\n$b2\n  end/" orca.inp
    else
      bonds=$(grep " { B " ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
      sed -i "s/%geom/%geom\n  modify_internal\n${bonds//$'\n'/\\n}\n  end/" orca.inp
    fi
    if [[ "$joblist" == "none" ]]; then
      joblist=$((10#${d#f}))
    else
      joblist=$joblist","$((10#${d#f}))
    fi
  else
    echo "$d - skipping because tsopt already set up"
  fi
  cd $wkdr
done

cp ~/git/DeYonker-lab-scripts/dwappett/1-array-tsopt 1-array-tsopt
sed -i "s/ASTART-AEND\%1/${joblist}%4/" 1-array-tsopt
echo ""
echo "created 1-array-tsopt"

