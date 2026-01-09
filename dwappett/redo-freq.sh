#!/bin/bash
# DAW 2025/01/09
# redo-freq.sh arg1
# arg1 is file listing dirs to do this for

for i in $(cat $1); do
 cd $i
 orca-extract-final-geom.sh orca.out 
 propagate_orca.sh freqcrash
 if (( $(ls *freqcrash-inp 2>/dev/null) )) && cmp -s $(ls *-freqcrash-inp | tail -1) orca.inp; then
  replace_orca_inp_geom.py
  sed -i "s/opt //" orca.inp
 fi
 cd -
done
