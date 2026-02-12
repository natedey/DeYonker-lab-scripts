#!/bin/bash
# DAW 2026-01-26
# CM project job status checking script, now looks at each stage of calculation
# usage:
#   check_cm_jobs.sh [file listing dirs]
# or:
#   check_cm_jobs.sh dir [dirname]
# or:
#   check_cm_jobs.sh asarray [file]

################################################################
### function for getting state lists to avoid repeating code ###
### arg1 = directory to check, arg2 = list file label        ###
################################################################
checkdirstate () {
  keywords=$(grep -e "Geometry Optimization Run" -e "Energy+Gradient Calculation" -e "ORCA TERMINATED NORMALLY" -e "THE OPTIMIZATION HAS CONVERGED" -e "The optimization did not converge" -e "Geometry optimization failed" -e "Recalc_Hess" -e "ORCA finished by error termination" -e "Calling Command" -e "borting the run" -e "\[file orca_" -e "Numerical calculation ISN'T COMPLETE" $1/orca.out)
  if grep -q "Geometry Optimization Run" <<< $keywords; then
    if grep -q "ORCA TERMINATED NORMALLY" <<< $keywords; then
     if grep -q "THE OPTIMIZATION HAS CONVERGED" <<< $keywords; then echo $1 >> check_${2}_done.txt
     elif grep -q "The optimization did not converge" <<< $keywords; then echo $1 >> check_${2}_maxcyc.txt
     #elif grep -q "Geometry optimization failed" <<< $keywords; then echo "$1 - geometry optimization failed" >> check_${2}_CHECK_MANUALLY.txt
     elif grep -q "Geometry optimization failed" <<< $keywords; then echo $1 >> check_${2}_optcrash.txt
     else echo "$1 - orca.out terminated normally but neither converged nor hit max cycles nor failed" >> check_${2}_CHECK_MANUALLY.txt
     fi
    else
     if grep -q $(ls $1/slurm*.err | tail -1 | awk -F/ '{print $NF}' | sed "s/slurm-//; s/.err//") <<< $runningjobs; then echo $1 >> check_${2}_running.txt
     elif grep -q "Numerical calculation ISN'T COMPLETE!" <<< $keywords; then echo "$1 - frequency calculation problem, check geometry" >> check_${2}_CHECK_MANUALLY.txt
     elif grep -q "THE OPTIMIZATION HAS CONVERGED" <<< $keywords; then echo $1 >> check_${2}_freqcrash.txt
     elif grep -q "Recalc_Hess 100" <<< $keywords; then echo "$1 - opt didn't finish with Recalc_Hess 100" >> check_${2}_CHECK_MANUALLY.txt
     elif grep -q -e "ORCA finished by error termination" -e "Calling Command" -e "borting the run" -e "\[file orca_" <<< $keywords; then echo $1 >> check_${2}_orcaerror.txt
     elif grep -q "CANCELLED AT .* DUE TO TIME LIMIT" $(ls $1/slurm*.err | tail -1); then echo $1 >> check_${2}_optcrash.txt
     #else echo $1 >> check_${2}_running.txt
     else echo "$1 - unrecognised termination" >> check_${2}_CHECK_MANUALLY.txt
     fi
    fi
  elif grep -q "Energy+Gradient Calculation" <<< $keywords; then
    optout=0
    for j in $(ls $1/*-out 2>/dev/null); do if grep -q "Geometry Optimization Run" $j; then optout=$j; fi; done
    if [[ "$optout" != "0" ]] && grep -q "THE OPTIMIZATION HAS CONVERGED" $optout; then
     if grep -q "ORCA TERMINATED NORMALLY" <<< $keywords; then echo $1 >> check_${2}_done.txt
     elif grep -q $(ls $1/slurm*.err | tail -1 | awk -F/ '{print $NF}' | sed "s/slurm-//; s/.err//") <<< $runningjobs; then echo $1 >> check_${2}_running.txt
     elif grep -q "Numerical calculation ISN'T COMPLETE" <<< $keywords; then echo "$1 - frequency calculation problem" >> check_${2}_CHECK_MANUALLY.txt
     else echo $1 >> check_${2}_freqcrash.txt
     fi
    else echo "$1 - can't find converged opt output but orca.out is only calculating frequencies" >> check_${2}_CHECK_MANUALLY.txt
    fi
  else echo "$1 - orca.out does not seem to be a geometry optimization or frequency calculation" >> check_${2}_CHECK_MANUALLY.txt
  fi
}

#################################
### Actual script starts here ###
#################################

SECONDS=0

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
 echo "check_cm_jobs.sh checks status of calculations for CM MD project
usage: check_cm_jobs.sh [file listing directories]
OR: check_cm_jobs.sh dir [directory] -----> just check one directory
OR: check_cm_jobs.sh asarray [file] -----> run as slurm array for speed
in each directory checked, script creates lists check_[job]_[status].txt
 jobs: initialopt / tsconstrained / tsopt / irc1 / irc2
 statuses: done / maxcyc / orcaerror / optcrash / freqcrash / imagmodeproblem / CHECK_MANUALLY
"
 exit
#elif [ -z "$1" ] && [ -f "new_dirs.txt" ]; then
# directories=$(cat new_dirs.txt)
# echo "checking from file new_dirs.txt by default"
elif [ -z "$1" ]; then
# echo "no arguments and no new_dirs.txt file to read as default!"
# exit
 directories="."
 echo "no argument given so checking current directory"
elif [[ "$1" == "dir" ]]; then
 directories=$2
 echo "checking directory $2"
elif [[ "$1" == "asarray" ]]; then
 ndir=$(cat $2 | wc -l)
 cp ~/git/DeYonker-lab-scripts/dwappett/1-checkjobs .
 sed -i "s/SETARRAY/1-$ndir/; s/SETLISTFILE/$2/" 1-checkjobs
 #sbatch 1-checkjobs
 exit
else
 directories=$(cat $1)
 echo "checking directories listed in file $1"
fi


wkdr=$(pwd)
runningjobs=$(squeue --me -t running -r -o "%A" -h)

for i in $(echo $directories); do
 echo $i
 cd $i
 rm check-new-jobs_done.txt check-new-jobs_maxcyc.txt check-new-jobs_freqcrash.txt check-new-jobs_optcrash.txt check-new-jobs_orcaerror.txt check-new-jobs_CHECK_MANUALLY.txt 1-array* 2> /dev/null
 rm check_initialopt_*.txt check_tsconstrained_*.txt check_tsopt_*.txt check_irc*.txt 2> /dev/null
 rm check_pending.txt 2> /dev/null
 for d in f*; do
  echo -ne "checking $i/$d \r"
  checkdirstate $d initialopt
  if [ -d $d/tsconstrained ] && [ -f $d/tsconstrained/orca.out ]; then checkdirstate $d/tsconstrained tsconstrained; else continue; fi
  if [ -d $d/tsopt ] && [ -f $d/tsopt/orca.out ]; then checkdirstate $d/tsopt tsopt; else continue; fi
  if [ -d $d/tsopt/irc1 ] && [ -f $d/tsopt/irc1/orca.out ]; then checkdirstate $d/tsopt/irc1 irc1; fi
  if [ -d $d/tsopt/irc2 ] && [ -f $d/tsopt/irc2/orca.out ]; then checkdirstate $d/tsopt/irc2 irc2; fi
 done
 # filter out pending jobs
 for j in $(squeue --me -t pending -r -o "%K_%j_%Z" -h | grep $(pwd)$); do
  jname=$(echo $j | awk -F_ '{print $2}' | sed "s/ORCA-//")
  dname=$(echo $j | awk -F_ '{ printf("f%05d\n",$1) }')
  if [[ ! $(grep -H $dname check_*.txt | grep -v -e "done" -e "running") ]]; then
   echo "dir $dname has pending $jname job, seems to be a new job not a restart" >> check_pending.txt
  else
   for k in $(grep -H $dname check_*.txt | grep -v -e "done" -e "running" | awk -F: '{print $1}'); do 
    echo "dir $dname has pending $jname job, removing from list $k to avoid possible duplication" >> check_pending.txt
    sed -i "\#$dname#d" $k
   done
  fi
 done
 # check tsopt done list and filter out any with extra imaginary frequencies
 if [[ $(ls check_tsopt_*.txt | grep -e "done" -e "freqcrash" -e "optcrash" -e "maxcyc" -e "orcaerror" 2> /dev/null) ]]; then
  for f in $(ls check_tsopt_*.txt | grep -e "done" -e "freqcrash" -e "optcrash" -e "maxcyc" -e "orcaerror"); do
   for j in $(cat $f); do
    if grep -q "VIBRATIONAL FREQUENCIES" $j/orca.out; then
     lastmodes=$(tac $j/orca.out | grep -m 1 -B 30 "VIBRATIONAL FREQUENCIES")
     nmode=$(grep "imaginary mode" <<< $lastmodes | wc -l)
     firstmode=$(grep " 6: " <<< $lastmodes | awk '{print $2}')
     if grep -q "tightopt" $j/orca.inp; then tightopt=1; else tightopt=0; fi
     if (( $(echo "$firstmode > -100" | bc -l) )); then
      if grep -q "modify_internal" $j/orca.inp; then
       echo "$j - $nmode imaginary modes, first mode is $firstmode" >> check_tsopt_tsmodegone.txt
      else
       echo "$j - $nmode imaginary modes, first mode is $firstmode, but modify_internal not added yet!" >> check_tsopt_tsmodegone.txt
      fi
      sed -i "\#$j#d" $f
     elif [[ "$f" == "check_tsopt_done.txt" ]] && [[ "$nmode" != 1 ]]; then
      if [[ "$tightopt" == 1 ]]; then
       echo "$j - $nmode imaginary modes, first mode is $firstmode, tightopt already on" >> check_tsopt_CHECK_MANUALLY.txt
      else
       echo "$j - $nmode imaginary modes, first mode is $firstmode" >> check_tsopt_extraimagmodes.txt
      fi
      sed -i "\#$j#d" $f
     fi
    fi
   done
  done
 fi
 # same for ircs
 for k in irc1 irc2; do
  if [ -f check_${k}_done.txt ]; then
   for j in $(cat check_${k}_done.txt); do
    nmode=$(tac $j/orca.out | grep -m 1 -B 30 "VIBRATIONAL FREQUENCIES" | grep "imaginary mode" | wc -l)
    if grep -q "tightopt" $j/orca.inp; then tightopt=1; else tightopt=0; fi
    if [[ "$nmode" != 0 ]]; then
     if [[ "$tightopt" == 1 ]]; then
      echo "$j - $nmode imaginary modes, tightopt already on" >> check_${k}_CHECK_MANUALLY.txt
     else
      echo "$j - $nmode imaginary modes" >> check_${k}_extraimagmodes.txt
     fi
     sed -i "\#$j#d" check_${k}_done.txt
    fi
   done
  fi
 done
 # finally remove any list files that are now empty after the pending stuff has been removed
 for j in check_*.txt; do
  if ! grep -q "f" $j; then rm $j; fi
 done
 cd $wkdr
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

