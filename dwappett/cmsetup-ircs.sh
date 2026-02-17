#!/bin/bash
# script to set up ircs for CM MD->QM project
# created DAW Jan 2026
# usage: cmsetup-ircs.sh [list file]

if [ -z "$1" ]; then
  1="check_tsopt_done.txt"
  echo "using default list: check_tsopt_done.txt"
elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  echo "usage: cmsetup-ircs.sh check_tsopt_done.txt
uses gen_irc_orca.py to set up irc calcs from the tsopt outputs
script will skip fxxxxx dirs which already have irc1/irc2 subdirs!"
elif [[ "$1" != "check_tsopt_done.txt" ]]; then
  echo "this script is designed to be used with the check_tsopt_done.txt list which is not what was provided
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
  cd $d/tsopt
  if [ ! -d "irc1" ] && [ ! -d "irc2" ]; then
    echo $d
    python ~/git/DeYonker-lab-scripts/gen_irc_orca.py
    if [[ "$joblist" == "none" ]]; then
      joblist=$((10#${d#f}))
    else
      joblist=$joblist","$((10#${d#f}))
    fi
  else
    echo "$d - skipping because ircs already set up"
  fi
  cd $wkdr
done

cp ~/git/DeYonker-lab-scripts/dwappett/1-array-irc1 1-array-irc1
sed -i "s/ASTART-AEND\%4/${joblist}%10/" 1-array-irc1

cp ~/git/DeYonker-lab-scripts/dwappett/1-array-irc1 1-array-irc2
sed -i "s/ASTART-AEND\%4/${joblist}%10/; s/irc1/irc2/" 1-array-irc2

echo ""
echo "created 1-array-irc1 and 1-array-irc2"

