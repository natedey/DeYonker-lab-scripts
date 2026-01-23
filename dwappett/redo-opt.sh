#!/bin/bash
# DAW 2025/01/12
# redo-opt.sh arg1 arg2
# arg1 is file listing dirs to do this for (required)
# arg2 is "orcaerror" or "optcrash" or "maxcyc" 
# - orcaerror: restart from beginning
# - optcrash: restart from beginning with calc_hess keyword, 
#    if calc_hess already present then add recalc_hess as well
#    after recalc_hess 200, go to recalc_hess 100
# - maxcyc: same as optcrash

if [[ "$1" == "-h" ]] || [[ "$1" == *"-help" ]]; then
  echo "redo-opt.sh arg1 arg2
arg1: file listing directories to do this in
arg2: type of processing - orcaerror / optcrash / maxcyc
script prepares slurm array file to run jobs in listed directories
for 'optcrash'/'maxcyc', sequentially adds calchess and recalchess keywords to input file to try to get the opt to converge
'orcaerror' problems are often not orca's fault so input files are left unchanged
"
exit
fi

for i in $(cat $1); do
 cd $i
 if [[ "$2" == "optcrash" ]] || [[ "$2" == "maxcyc" ]]; then
  propagate_orca.sh $2
  if grep -q "Calc_Hess" orca.inp; then
   if grep -q "Recalc_Hess" orca.inp
    sed -i "s/Recalc_Hess 200/Recalc_Hess 100/" orca.inp
   else
    sed -i "s/Calc_Hess true/Calc_Hess true\n  Recalc_Hess 200/" orca.inp
   fi
  else
   sed -i "s/%geom/%geom\n  Calc_Hess true/" orca.inp
  fi
 fi
 cd -
done

cp ~/git/DeYonker-lab-scripts/dwappett/1-array 1-array-redo-$2
joblist="none"
for j in $(cat check-new-jobs_$2.txt); do
 if [[ "$joblist" == "none" ]]; then
  joblist=$((10#${j#f}))
 else
  joblist=$joblist","$((10#${j#f}))
 fi
done
sed -i "s/ASTART-AEND\%4/${joblist}%1/" 1-array-redo-$2
sed -i "s/time=24:00:00/time=48:00:00/" 1-array-redo-$2
