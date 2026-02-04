#!/bin/bash
# script to set up ircs for CM MD->QM project
# created DAW Jan 2026
# usage: cmsetup-ircs.sh [list file]

wkdr=$(pwd)
joblist="none"
for i in $(cat $1); do
  d=$(echo $i | awk -F/ '{print $1}')
  cd $d/tsopt
  if [ ! -d "irc1" ] && [ ! -d "irc2" ]; then
    python ~/git/DeYonker-lab-scripts/gen_irc_orca.py
    if [[ "$joblist" == "none" ]]; then
      joblist=$((10#${d#f}))
    else
      joblist=$joblist","$((10#${d#f}))
    fi
  fi
  cd $wkdr
done

cp ~/git/DeYonker-lab-scripts/dwappett/1-array-irc1 1-array-irc1
sed -i "s/ASTART-AEND\%4/${joblist}%1/" 1-array-irc1

cp ~/git/DeYonker-lab-scripts/dwappett/1-array-irc1 1-array-irc2
sed -i "s/ASTART-AEND\%4/${joblist}%1/; s/irc1/irc2/" 1-array-irc2

