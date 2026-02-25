#!/bin/bash
# DAW 2025/01/09
# redo-freq.sh arg1
# arg1 is file listing dirs to do this for

if [[ "$1" == "-h" ]] || [[ "$1" == *"-help" ]]; then
  echo "redo-freq.sh arg1
arg1: file listing directories to do this in
script retrieves optimised geometry and sets up freq only calc on that structure
also prepares slurm array file to run jobs in listed directories
"
  exit
fi

calctype=$(echo ${1//.txt} | awk -F_ '{print $2}' )
redotype="freqcrash"
wkdr=$(pwd)
joblist="none"

if [ -f 1-array-redo-$calctype-$redotype ]; then
  echo "1-array-redo-$calctype-$redotype exists. You've run this already..."
  echo "You can make sure you've submitted the existing 1-array-redo-$calctype-$redotype by running cm-md-status.py
If the redo array is running, the $redotype labels in the $calctype columns will be appended with running/queued and coloured blue instead of red"
  exit
fi


for i in $(cat $1); do
 cd $i
 echo $i
 slurmjob=$(ls slurm-*.err | tail -1 | sed "s/slurm-//; s/.err//")
 if [ -d /scratch/$USER/$slurmjob ] && cmp -s /scratch/$USER/$slurmjob/orca.inp orca.inp; then
  cp /scratch/$USER/$slurmjob/orca.xyz .
 else orca-extract-final-geom.sh orca.out
 fi
 propagate_orca.sh freqcrash
 if [ -f orca.xyz ] && (( $(( $(head -1 orca.xyz) + 2 )) == $(cat orca.xyz | wc -l) )); then
  if (( $(ls *freqcrash-inp 2>/dev/null) )) && ( cmp -s $(ls *-freqcrash-inp | tail -1) orca.inp || cmp -si 5:1 $(ls *-freqcrash-inp | tail -1) orca.inp ); then
   replace_orca_inp_geom.py
   sed -i "s/opt //; s/optts //" orca.inp
   sed -i "s/optts //" orca.inp
   sed -i "/Calc_Hess/d; /Recalc_Hess/d; /inhess/d" orca.inp
   d=$(echo $i | awk -F/ '{print $1}')
   if [[ "$joblist" == "none" ]]; then
    joblist=$((10#${d#f}))
   else
    joblist=$joblist","$((10#${d#f}))
   fi
  else echo "error propagating orca.inp for $i, not overwriting" >> $wkdr/freq-restart-issues.txt
  fi
 else echo "error retrieving optimized coordinates for $i" >> $wkdr/freq-restart-issues.txt
 fi
 cd $wkdr
done

#cp ~/git/DeYonker-lab-scripts/dwappett/1-array 1-array-redo-freqcrash
#sed -i "s/ASTART-AEND\%4/${joblist}%1/" 1-array-redo-freqcrash

if [[ "$calctype" == "initialopt" ]]; then
  cp ~/git/DeYonker-lab-scripts/dwappett/1-array 1-array-redo-initialopt-$redotype
  sed "s/job-name=ORCAJOB/job-name=ORCA-initialopt/" 1-array-redo-initialopt-$redotype
  jobfile="1-array-redo-initialopt-$redotype"
elif [[ "$calctype" == "irc2" ]]; then
  cp ~/git/DeYonker-lab-scripts/dwappett/1-array-irc1 1-array-redo-irc2-$redotype
  sed -i "s/irc1/irc2/" 1-array-redo-irc2-$redotype
  jobfile="1-array-redo-irc2-$redotype"
else
  cp ~/git/DeYonker-lab-scripts/dwappett/1-array-$calctype 1-array-redo-$calctype-$redotype
  jobfile="1-array-redo-$calctype-$redotype"
fi

sed -i "s/ASTART-AEND\%1/${joblist}%1/" $jobfile
echo ""
echo "created $jobfile"
