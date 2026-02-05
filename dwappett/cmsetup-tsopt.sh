#!/bin/bash
# script to set up full ts opts for CM MD->QM project
# created DAW Jan 2026
# usage: cmsetup-tsopt.sh [list file]

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
sed -i "s/ASTART-AEND\%4/${joblist}%1/" 1-array-tsopt
