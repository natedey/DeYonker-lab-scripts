#!/bin/bash
# DAW 2025/01/09
# redo-freq.sh arg1
# arg1 is file listing dirs to do this for

joblist="none"
for i in $(cat $1); do
 cd $i
 #orca-extract-final-geom.sh orca.out 
 slurmjob=$(ls slurm-*.err | tail -1 | sed "s/slurm-//; s/.err//")
 if [ -d /scratch/$USER/$slurmjob ] && cmp -s /scratch/$USER/$slurmjob/orca.inp orca.inp; then
  cp /scratch/$USER/$slurmjob/orca.xyz .
 else orca-extract-final-geom.sh orca.out
 fi
 propagate_orca.sh freqcrash
 if [ -f orca.xyz ] && (( $(( $(head -1 orca.xyz) + 2 )) == $(cat orca.xyz | wc -l) )); then
  if (( $(ls *freqcrash-inp 2>/dev/null) )) && cmp -s $(ls *-freqcrash-inp | tail -1) orca.inp; then
   replace_orca_inp_geom.py
   sed -i "s/opt //" orca.inp
   if [[ "$joblist" == "none" ]]; then
    joblist=$((10#${i#f}))
   else
    joblist=$joblist","$((10#${i#f}))
   fi
  else echo "error propagating orca.inp for $i, not overwriting" >> freq-restart-issues.txt
  fi
 else echo "error retrieving optimized coordinates for $i" >> freq-restart-issues.txt
 fi
 cd -
done

cp ~/git/DeYonker-lab-scripts/dwappett/1-array 1-array-redo-freqcrash
sed -i "s/ASTART-AEND\%4/${joblist}%1/" 1-array-redo-freqcrash


