#!/bin/bash

SECONDS=0

for i in $(cat new_dirs.txt); do
 echo $i
 cd $i
 rm check-new-jobs_done.txt check-new-jobs_maxcyc.txt check-new-jobs_freqcrash.txt check-new-jobs_optcrash.txt check-new-jobs_orcaerror.txt check-new-jobs_CHECK_MANUALLY.txt 2> /dev/null
 for d in f*; do
   if grep -q "Geometry Optimization Run" $d/orca.out; then
     if grep -q "ORCA TERMINATED NORMALLY" $d/orca.out; then
      if grep -q "THE OPTIMIZATION HAS CONVERGED" $d/orca.out; then echo $d >> check-new-jobs_done.txt
      elif grep -q "The optimization did not converge" $d/orca.out; then echo $d >> check-new-jobs_maxcyc.txt
      else echo "$d - orca.out terminated normally but neither converged nor hit max cycles" >> check-new-jobs_CHECK_MANUALLY.txt
      fi
     else
      if grep -q "THE OPTIMIZATION HAS CONVERGED" $d/orca.out; then echo $d >> check-new-jobs_freqcrash.txt
      elif grep -q "aborting the run" $d/orca.out; then echo $d >> check-new-jobs_orcaerror.txt
      else echo $d >> check-new-jobs_optcrash.txt
      fi
     fi
   elif grep -q "Energy+Gradient Calculation" $d/orca.out; then
     optout=0
     for j in $(ls $d/*-out 2>/dev/null); do if grep -q "Geometry Optimization Run" $j; then optout=$j; fi; done
     if [[ "$optout" != "0" ]] && grep -q "THE OPTIMIZATION HAS CONVERGED" $optout; then
      if grep -q "ORCA TERMINATED NORMALLY" $d/orca.out; then echo $d >> check-new-jobs_done.txt
      else echo $d >> check-new-jobs_freqcrash.txt
      fi
     else echo "$d - can't find converged opt output but orca.out is only calculating frequencies" >> check-new-jobs_CHECK_MANUALLY.txt
     fi
   else echo "$d - orca.out does not seem to be a geometry optimization or frequency calculation" >> check-new-jobs_CHECK_MANUALLY.txt
   fi
 done
 cd ..
done


if (( $SECONDS > 3600 )) ; then
    let "hours=SECONDS/3600"
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)"
elif (( $SECONDS > 60 )) ; then
    let "minutes=(SECONDS%3600)/60"
    let "seconds=(SECONDS%3600)%60"
    echo "Completed in $minutes minute(s) and $seconds second(s)"
else
    echo "Completed in $SECONDS seconds"
fi

