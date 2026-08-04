#!/bin/bash
# script to set up product guesses for NEB-based workflow
# created DAW July 2026
# usage: cmsetup-productguess.sh [list file]
# only sets up dirs/jobs if product dir doesn't exist yet so stuff isn't overwritten

if [ -z "$1" ]; then
  set check_initialopt_done.txt
  echo "using default list: $1"
elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  echo "usage: cmsetup-productguess.sh check_initialopt_done.txt
sets up a product guess structure and prepares an input for the opt
script will skip fxxxxx dirs which already have a product subdir!"
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
  if [ ! -d "product" ]; then
    echo $i
    xyz_to_pdb.py -pdb model_*_template.pdb -name ${i}-opt
    mkdir product
    cd product
    align_TSA_and_replace.py -modpdb ../${i}-opt.pdb -md -tspdb ~/git/DeYonker-lab-scripts/NEB-TS_CM_workflow/res12-irc2-out.pdb -newpdb old_product_aligned.pdb
    mv tsguess.pdb productguess.pdb
    if [ -f "tsguess_close_atoms.txt" ]; then mv tsguess_close_atoms.txt productguess_close_atoms.txt; fi
    write_input.py -pdb productguess.pdb -format orca -intmp ~/git/DeYonker-lab-scripts/CM_MD_to_QM_project/orcaxtb_intmp.txt -c -2 -inpn orca.inp
    if [[ "$joblist" == "none" ]]; then
      joblist=$((10#${i#f}))
    else
      joblist=$joblist","$((10#${i#f}))
    fi
  else
    echo "$i - skipping because product already set up"
  fi
  cd $wkdr
done

cp ~/git/DeYonker-lab-scripts/NEB-TS_CM_workflow/1-array-product 1-array-product
sed -i "s/ASTART-AEND\%1/${joblist}%4/" 1-array-product

echo ""
echo "created 1-array-product"
