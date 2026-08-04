#!/bin/bash
# script to set up NEB-TS for NEB-based workflow
# created DAW July 2026
# usage: cmsetup-neb-ts.sh [list file]
# only sets up dirs/jobs if neb-ts dir doesn't exist yet so stuff isn't overwritten

if [ -z "$1" ]; then
  set check_product_done.txt
  echo "using default list: $1"
elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  echo "usage: cmsetup-neb-ts.sh check_product_done.txt
sets up an neb-ts calc with the reactant (initialopt) and product strucs
script will skip fxxxxx dirs which already have a neb-ts subdir!"
  exit
elif [[ "$1" != "check_product_done.txt" ]]; then
  echo "this script is designed to be used with the check_product_done.txt list which is not what was provided
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
for i in $(awk '{print $1}' $1); do
  d=$(echo $i | awk -F/ '{print $1}')
  cd $d
  if [ ! -d "neb-ts" ]; then
    echo $d
    mkdir neb-ts
    cp product/orca.xyz neb-ts/product.xyz
    cd neb-ts
    write_input.py -pdb ../${d}-opt.pdb -format orca -intmp ~/git/DeYonker-lab-scripts/NEB-TS_CM_workflow/nebts_intmp.txt -c -2 -inpn orca.inp
    sed -i "s/*xyz/%neb\n  neb_end_xyzfile \"product.xyz\"\nend\n*xyz/" orca.inp
    if [[ "$joblist" == "none" ]]; then
      joblist=$((10#${d#f}))
    else
      joblist=$joblist","$((10#${d#f}))
    fi
  else
    echo "$d - skipping because neb-ts already set up"
  fi
  cd $wkdr
done

cp ~/git/DeYonker-lab-scripts/NEB-TS_CM_workflow/1-array-neb-ts 1-array-neb-ts
sed -i "s/ASTART-AEND\%1/${joblist}%4/" 1-array-neb-ts

echo ""
echo "created 1-array-neb-ts"
