#!/bin/bash
# DAW 2025/01/12
# redo-opt.sh arg1
# arg1 is file listing dirs to do this for
# filename needs to be check_[stage]_[status].txt because this info will be used to determine what to do
# - orcaerror: restart from beginning
# - optcrash: restart from beginning with calc_hess keyword, 
#    if calc_hess already present then add recalc_hess as well
#    after recalc_hess 200, go to recalc_hess 100
# - maxcyc: same as optcrash

if [[ "$1" == "-h" ]] || [[ "$1" == *"-help" ]]; then
  echo "redo-opt.sh arg1
arg1: file listing directories to do this in
script prepares slurm array file to run jobs in listed directories and determines how to restart based on filename
for 'optcrash'/'maxcyc', sequentially adds calchess and recalchess keywords to input file to try to get the opt to converge
'orcaerror' problems are often not orca's fault so input files are left unchanged
'extraimagmodes' (tsopt and ircs only) sets up tightopt on optimised struc
"
  exit
fi

calctype=$(echo ${1//.txt} | awk -F_ '{print $2}' )
redotype=$(echo ${1//.txt} | awk -F_ '{print $3}' )
wkdr=$(pwd)
joblist="none"

if [ -f 1-array-redo-$calctype-$redotype ]; then
  echo "1-array-redo-$calctype-$redotype exists. You've run this already..."
  echo "You can make sure you've submitted the existing 1-array-redo-$calctype-$redotype by running cm-md-status.py
If the redo array is running, the $redotype labels in the $calctype columns will be appended with running/queued and coloured blue instead of red"
  exit
elif [[ "$redotype" == "freqcrash" ]]; then
  echo "this script does not restart freqcrash jobs! run the command below instead:"
  echo "redo-freq.sh $1"
  exit
fi

for i in $(awk '{print $1}' $1); do
 echo $i
 cd $i
 if [[ "$redotype" == "optcrash" ]] || [[ "$redotype" == "maxcyc" ]]; then
  propagate_orca.sh $redotype
  if [[ "$calctype" == "tsopt" ]]; then
    if grep -q "Recalc_Hess" orca.inp; then
     sed -i "s/Recalc_Hess 200/Recalc_Hess 100/" orca.inp
    else
     sed -i "s/  constraints/  Recalc_Hess 200\n  constraints/" orca.inp
    fi
    if ! grep -q "modify_internal" orca.inp; then
      bonds=$(grep " { B " ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
      sed -i "s/%geom/%geom\n  modify_internal\n${bonds//$'\n'/\\n}\n  end/" orca.inp
    fi
  else
    if ! grep -q "Calc_Hess" orca.inp; then
     sed -i "s/%geom/%geom\n  Calc_Hess true\n  Recalc_Hess 200/" orca.inp
    elif grep -q "Calc_Hess" orca.inp && ! grep -q "Recalc_Hess" orca.inp; then
     sed -i "s/Calc_Hess true/Calc_Hess true\n  Recalc_Hess 200/" orca.inp
    else
     sed -i "s/Recalc_Hess 200/Recalc_Hess 100/" orca.inp
    fi
  fi
 elif [[ "$redotype" == "extraimagmodes" ]]; then
  propagate_orca.sh $redotype
  if ! grep -q -e " opt " -e " optts " orca.inp; then
   sed -i "s/numfreq/opt numfreq/" orca.inp
  else 
   savedxyz=$(ls *-$redotype-xyz | tail -1)
   replace_orca_inp_geom.py -xyz $savedxyz
  fi
  savedhess=$(ls *-$redotype-hess | tail -1)
  sed -i "s/ALPB(water)/ALPB(water) tightopt/" orca.inp
  if [[ "$calctype" == "tsopt" ]]; then
   sed -i "s/ opt / optts /" orca.inp #wont do anything if already optts but fixes if last job was only freq and the sed command earlier has just added in opt
   sed -i "s/tsconstrained.hess/$savedhess/" orca.inp
   if ! grep -q "modify_internal" orca.inp; then
    bonds=$(grep " { B " ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
    sed -i "s/%geom/%geom\n  modify_internal\n${bonds//$'\n'/\\n}\n  end/" orca.inp
   fi
  elif ! grep -q "inhessname" orca.inp; then
   sed -i "s/%geom/%geom\n  inhess read\n  inhessname \"$savedhess\"/" orca.inp
  fi
 elif [[ "$redotype" == "tsmodegone" ]] && ! grep -q "modify_internal" orca.inp; then
  propagate_orca.sh $redotype
  bonds=$(grep " { B " ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
  sed -i "s/%geom/%geom\n  modify_internal\n${bonds//$'\n'/\\n}\n  end/" orca.inp
 elif [[ "$redotype" == "tsmodegone" ]] && grep -q "modify_internal" orca.inp; then
  echo "$i already has modify_internal added. skipping..."
  cd $wkdr
  continue
 fi 
 d=$(echo $i | awk -F/ '{print $1}')
 if [[ "$joblist" == "none" ]]; then
  joblist=$((10#${d#f}))
 else
  joblist=$joblist","$((10#${d#f}))
 fi
 cd $wkdr
done

cd $wkdr
if [[ "$calctype" == "initialopt" ]]; then
  cp ~/git/DeYonker-lab-scripts/dwappett/1-array 1-array-redo-initialopt-$redotype
  sed -i "s/job-name=ORCAJOB/job-name=ORCA-initialopt/" 1-array-redo-initialopt-$redotype
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
#sed -i "s/time=24:00:00/time=48:00:00/" $jobfile
echo ""
echo "created $jobfile" 
