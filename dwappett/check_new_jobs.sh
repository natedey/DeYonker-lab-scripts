#!/bin/bash

SECONDS=0

for i in $(cat new_dirs.txt); do
 echo $i
 for d in $i/f*; do
  if grep -q "ORCA TERMINATED NORMALLY" $d/orca.out; then
   if grep -q "THE OPTIMIZATION HAS CONVERGED" $d/orca.out; then echo $d >> check-new-jobs_done.txt
   elif grep -q "The optimization did not converge" $d/orca.out; then echo $d >> check-new-jobs_maxcyc.txt
   fi
  else 
   if grep -q "HURRAY" $d/orca.out; then echo $d >> check-new-jobs_freqcrash.txt
   else echo $d >> check-new-jobs_optcrash.txt
   fi
  fi
 done
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

