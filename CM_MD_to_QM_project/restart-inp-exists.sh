#!/bin/bash
# HKS 04/10/2025
# restart-inp-exists.sh arg1

# Usage:
#    restart-inp-exists.sh arg1 
#                          arg1 corresponds to a column in the cm-md-status.py output table. 
#                  Allowed arg1 values - initialopt, tsconstrained, tsopt, irc1, irc2


if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
 echo " This script prepares slurm array file to run jobs for directories that show inp_exists in the cm-md-status.py output table.
 usage: restart-inp-exists.sh arg1 
 arg 1 corresponds to a column in the cm-md-status.py output table. 
 Allowed arg1 values are initialopt, tsconstrained, tsopt, irc1, irc2.
"
 exit 
fi

joblist="none"
wkdr=$(pwd)

calctype="$1"

if [ "$1" = "initialopt" ]; then
    col=2
elif [ "$1" = "tsconstrained" ]; then
    col=3
elif [ "$1" = "tsopt" ]; then
    col=4
elif [ "$1" = "irc1" ]; then
    col=5
elif [ "$1" = "irc2" ]; then
    col=6
else
    echo "Unknown type: $1"
    exit 1
fi

list_inp_exists=$(cm-md-status.py | awk -v c="$col" '$c=="inp_exists" {print $1}')

for i in $list_inp_exists; do
  d=$(echo "$i" | awk -F/ '{print $1}')
  num=${d#f}
  if [[ "$joblist" == "none" ]]; then
    joblist=$((10#$num))
  else
    joblist="$joblist,$((10#$num))"
  fi
done



cd $wkdr
if [[ "$calctype" == "initialopt" ]]; then
  cp ~/git/DeYonker-lab-scripts/CM_MD_to_QM_project/1-array 1-array-initialopt-restart
  sed -i "s/job-name=ORCAJOB/job-name=ORCA-initialopt/" 1-array-initialopt-restart
  jobfile="1-array-initialopt-restart"
elif [[ "$calctype" == "irc2" ]]; then
  cp ~/git/DeYonker-lab-scripts/CM_MD_to_QM_project/1-array-irc1 1-array-irc2-restart
  sed -i "s/irc1/irc2/" 1-array-irc2-restart
  jobfile="1-array-irc2-restart"
else
  cp ~/git/DeYonker-lab-scripts/CM_MD_to_QM_project/1-array-$calctype 1-array-$calctype-restart
  jobfile="1-array-$calctype-restart"
fi
  




sed -i "s/ASTART-AEND\%1/${joblist}%1/" "$jobfile"
#sed -i "s/time=24:00:00/time=48:00:00/" $jobfile
echo ""
echo "created $jobfile" 
