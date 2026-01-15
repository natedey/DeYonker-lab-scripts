#!/bin/bash
# DAW 2025/01/12
# redo-opt.sh arg1 arg2
# arg1 is file listing dirs to do this for (required)
# arg2 is "orcaerror" or "optcrash" or "maxcyc" 
# - orcaerror: restart from beginning
# - optcrash: restart from beginning with calc_hess keyword, 
#    if calc_hess already present then add recalc_hess as well
# - maxcyc: same as optcrash

for i in $(cat $1); do
 cd $i
 if [[ "$2" == "optcrash" ]] || [[ "$2" == "maxcyc" ]]; then
  propagate_orca.sh $2
  if greq -q "Calc_Hess" orca.inp; then
   sed -i "s/Calc_Hess true/Calc_Hess true\n  Recalc_Hess 200/" orca.inp
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
sed -i "s/time=12:00:00/time=48:00:00/" 1-array-redo-$2
