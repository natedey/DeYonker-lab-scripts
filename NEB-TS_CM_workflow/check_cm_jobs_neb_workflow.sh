#!/bin/bash
# DAW 2026-07-07
# CM project job status checking script for reactant -> product -> neb-ts workflow

################################################################
### function for getting state lists to avoid repeating code ###
### arg1 = directory to check, arg2 = list file label        ###
################################################################
checkdirstate () {
  # grep orca.out once for all the calc type/termination/success/error/settings keywords that this function checks, for efficiency
  keywords=$(grep -e "Geometry Optimization Run" -e "Energy+Gradient Calculation" -e "Nudged Elastic Band Calculation" -e "ORCA TERMINATED NORMALLY" -e "THE OPTIMIZATION HAS CONVERGED" -e "THE TS OPTIMIZATION HAS CONVERGED" -e "The optimization did not converge" -e "Geometry optimization failed" -e "Recalc_Hess" -e "ORCA finished by error termination" -e "Calling Command" -e "borting the run" -e "\[file orca_" -e "the SCF has not converged. There may be a way out but we have to stop here" -e "Numerical calculation ISN'T COMPLETE" -e "VIBRATIONAL FREQUENCIES" -e "tightopt" -e "modify_internal" $1/orca.out)

  ### all job types: assign initial state ###
  # first check for manual override. if file contains word "exclude", then model will go into excluded list, otherwise it'll go into check_manually
  if [ -f "$1/overwrite-check.txt" ]; then 
    if grep -q -i "exclude" $1/overwrite-check.txt; then echo "$1 - $(cat $1/overwrite-check.txt)" >> check_${2}_excluded.txt; state="skipped"
    else echo "$1 - $(cat $1/overwrite-check.txt)" >> check_${2}_CHECK_MANUALLY.txt; state="skipped"
    fi
  # otherwise determine job state from output keywords
  elif grep -q "Geometry Optimization Run" <<< $keywords; then
    if grep -q "ORCA TERMINATED NORMALLY" <<< $keywords; then
     if grep -q "THE OPTIMIZATION HAS CONVERGED" <<< $keywords; then 
       # geom opt + terminated normally + converged = done
       echo $1 >> check_${2}_done.txt; state="done"
     elif grep -q "The optimization did not converge" <<< $keywords; then 
       # geom opt + terminated normally + not converged = maxcyc
       echo $1 >> check_${2}_maxcyc.txt; state="maxcyc"
     elif grep -q "Geometry optimization failed" <<< $keywords; then 
       # geom opt + terminated normally + failed = optcrash
       echo $1 >> check_${2}_optcrash.txt; state="optcrash"
       # geom opt + terminated normally + no recognised convergence message = check_manually
     else 
       echo "$1 - orca.out terminated normally but neither converged nor hit max cycles nor failed" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
     fi
     # if assigned maxcyc or optcrash but already doing recalc_hess 100, move to check_manually
     if [[ "$state" == "maxcyc" || "$state" == "optcrash" ]] && grep -q  "Recalc_Hess 100" <<< $keywords; then
      sed -i "\#$1#d" check_${2}_$state.txt
      echo "$1 - opt didn't finish with Recalc_Hess 100" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
     fi
    else
     if grep -q $(ls $1/slurm*.err | tail -1 | awk -F/ '{print $NF}' | sed "s/slurm-//; s/.err//") <<< $runningjobs; then 
       # geom opt + not terminated normally + last slurm err file in dir belongs to a currently running job = running
       echo $1 >> check_${2}_running.txt; state="running"
     elif grep -q "Numerical calculation ISN'T COMPLETE!" <<< $keywords; then 
       # geom opt + not terminated normally + problem in freq calc = check_manually
       echo "$1 - frequency calculation problem, check geometry" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
     elif grep -q "THE OPTIMIZATION HAS CONVERGED" <<< $keywords; then 
       # geom opt + not terminated normally + opt converged = freqcrash
       echo $1 >> check_${2}_freqcrash.txt; state="freqcrash"
     elif grep -q "Recalc_Hess 100" <<< $keywords; then 
       # geom opt + not terminated normally + recalc_hess 100 = check_manually
       echo "$1 - opt didn't finish with Recalc_Hess 100" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
     elif grep -q "the SCF has not converged. There may be a way out but we have to stop here" <<< $keywords; then
       # geom opt + not terminated normally + SCF not converged = check_manually
       echo "$1 - SCF convergence problem, check geometry" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
     elif grep -q -e "ORCA finished by error termination" -e "Calling Command" -e "borting the run" -e "\[file orca_" <<< $keywords; then 
       # geom opt + not terminated normally + error message = orcaerror
       echo $1 >> check_${2}_orcaerror.txt; state="orcaerror"
     elif grep -q "CANCELLED AT .* DUE TO TIME LIMIT" $(ls $1/slurm*.err | tail -1); then 
       # geom opt + not terminated normally + slurm killed at time limit = optcrash
       echo $1 >> check_${2}_optcrash.txt; state="optcrash"
     else 
       # geom opt + not terminated normally + no recognised ending keywords = check_manually
       echo "$1 - unrecognised termination" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
     fi
    fi
  elif grep -q "Energy+Gradient Calculation" <<< $keywords; then
    # check that there is a previous successful opt calculation
    optout=0
    for j in $(ls $1/*-out 2>/dev/null); do 
      if grep -q -e "Geometry Optimization Run" -e "Nudged Elastic Band Calculation" $j && grep -q "OPTIMIZATION HAS CONVERGED" $j ; then optout=$j; fi; 
    done
    # if there's a previous successful opt
    if [[ "$optout" != "0" ]]; then
     if grep -q "ORCA TERMINATED NORMALLY" <<< $keywords; then 
       # opt converged in previous job + this freq calc done = done
       echo $1 >> check_${2}_done.txt; state="done"
     elif grep -q $(ls $1/slurm*.err | tail -1 | awk -F/ '{print $NF}' | sed "s/slurm-//; s/.err//") <<< $runningjobs; then 
       # opt converged in previous job + this freq calc running = running
       echo $1 >> check_${2}_running.txt; state="running"
     elif grep -q "Numerical calculation ISN'T COMPLETE" <<< $keywords; then 
       # opt converged in previous job + this freq calc had problem = check_manually
       echo "$1 - frequency calculation problem" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
     else 
       # opt converged in previous job + this freq calc not done/running/failed = freqcrash
       echo $1 >> check_${2}_freqcrash.txt; state="freqcrash"
     fi
    else 
     # no previous converged opt (doesn't matter what status of freq calc is because it shouldn't be being done) = check_manually
     echo "$1 - can't find converged opt output but orca.out is only calculating frequencies" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
    fi
  elif grep -q "Nudged Elastic Band Calculation" <<< $keywords; then
    if grep -q $(ls $1/slurm*.err | tail -1 | awk -F/ '{print $NF}' | sed "s/slurm-//; s/.err//") <<< $runningjobs; then
       # neb-ts + last slurm err file in dir belongs to a currently running job = running
       echo $1 >> check_${2}_running.txt; state="running"
    elif grep -q "THE TS OPTIMIZATION HAS CONVERGED" <<< $keywords; then
     if grep -q "ORCA TERMINATED NORMALLY" <<< $keywords; then
       # neb-ts + terminated normally + converged = done
       echo $1 >> check_${2}_done.txt; state="done"
     else
       # neb-ts + converged + not terminated & not running = freqcrash
       echo $1 >> check_${2}_freqcrash.txt; state="freqcrash"
     fi 
    else
      # all other neb-ts jobs go to check_manually for now bc I dunno what errors to expect
      echo $1 >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
    fi
  else
    # no "Geometry Optimization Run" or "Energy+Gradient Calculation" or "Nudged Elastic Band Calculation" keyword = check_manually
    echo "$1 - orca.out does not seem to be a geometry optimization, frequency calculation, or neb-ts calculation" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
  fi

  ### all job types: check how many times orcaerror jobs have been tried and reassign state if needed ###
  if [[ "$state" == "orcaerror" ]]; then
   Nsavedout=$(ls $1/*-out 2>/dev/null | grep -v -e slurm -e rinrus | wc -l)
   Nslurm=$(ls $1/slurm-*.err | wc -l)
   Norcaerror=$(( Nslurm - Nsavedout ))
   # if we've hit third attempt at restarting orcaerror and still no success, move into check_manually bc this is probably a real error
   if [ $Norcaerror -ge 3 ]; then
    sed -i "\#$1#d" check_${2}_$state.txt
    echo "$1 - hit orcaerror 3+ times, check inp and geometry" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
   fi
  fi

  ### check imaginary modes and reassign state if needed ###
  if [[ "$state" != "running" ]] && [[ "$state" != "skipped" ]] && grep -q "VIBRATIONAL FREQUENCIES" <<< $keywords; then
   # note: just grepping "imaginary mode" normally will also find all modes in (re)calc_hess steps but we only want final one!
   # have to read file from end (tac = backwards cat) and stop at first frequencies block ("-m 1 -B 30" = print only first match and 30 lines before it (remember we're reading backwards))
   lastmodes=$(tac $1/orca.out | grep -m 1 -B 30 "VIBRATIONAL FREQUENCIES")
   nmode=$(grep "imaginary mode" <<< $lastmodes | wc -l)
   firstmode=$(grep " 6: " <<< $lastmodes | awk '{print $2}')
   if grep -q "tightopt" <<< $keywords; then tightopt=1; else tightopt=0; fi
   # reassign jobs based on nmode/firstmode/tightopt
   if [[ "$2" == "neb-ts" ]] && (( $(echo "$firstmode > -100" | bc -l) )); then
    # ts + any state + magnitude of biggest imag mode < 100 = move to check_manually bc ts mode is gone
    sed -i "\#$1#d" check_${2}_$state.txt
    echo "$1 - $nmode imaginary modes, first mode is $firstmode, ts mode gone" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
   elif [[ "$2" == "neb-ts" ]] && [[ "$state" == "done" ]] && [[ "$nmode" != 1 ]]; then
    # neb-ts + done + >1 imaginary modes = move to check_manually
    sed -i "\#$1#d" check_${2}_$state.txt
    echo "$1 - $nmode imaginary modes, first mode is $firstmode" >> check_${2}_CHECK_MANUALLY.txt; state="CHECK_MANUALLY"
   elif [[ "$2" == "initialopt" || "$2" == "product" ]] && [[ "$state" == "done" ]] && [[ "$nmode" != 0 ]]; then
    if [[ "$tightopt" == 1 ]]; then
     if (( $(echo "$firstmode < -40" | bc -l) )) || [[ "$nmode" -gt 2 ]]; then
      # r/p + done + tightopt on + imag mode magnitude > 40 AND/OR >2 imaginary modes = move to excluded
      echo "$1 - $nmode imaginary modes, first mode is $firstmode" >> check_${2}_excluded.txt
      sed -i "\#$1#d" check_${2}_done.txt
     else
      # r/p + done + tightopt on + imag mode(s) acceptable = keep in done but make note of modes
      sed -i "s#$1#$1 - $nmode imaginary modes, first mode is $firstmode, tightopt already on#" check_${2}_done.txt
     fi
    else
     # r/p + done + tightopt not on yet = move to extraimagmodes
     echo "$1 - $nmode imaginary modes, first mode is $firstmode" >> check_${2}_extraimagmodes.txt
     sed -i "\#$1#d" check_${2}_done.txt
    fi
   fi
  fi
}



#################################
### Actual script starts here ###
#################################

SECONDS=0

if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
 echo "DAW HAS NOT CHANGED THIS HELP MESSAGE FROM ORIGINAL VERSION - ACCEPTED ARGS SAME BUT JOBS/STATUSES NOT CORRECT
check_cm_jobs.sh checks status of calculations for CM MD project
usage: check_cm_jobs.sh [file listing directories]
OR: check_cm_jobs.sh dir [directory] -----> just check one directory
OR: check_cm_jobs.sh asarray [file] -----> run as slurm array for speed
in each directory checked, script creates lists check_[job]_[status].txt
 jobs: initialopt / tsconstrained / tsopt / irc1 / irc2
 statuses: done / maxcyc / orcaerror / optcrash / freqcrash / imagmodeproblem / CHECK_MANUALLY
if you need to override automatically checked status: make a file in the dir called overwrite-check.txt
 and the dir will be added to the relevant CHECK_MANUALLY list with the contents of that file
"
 exit
elif [ -z "$1" ]; then
 directories="."
 echo "no argument given so checking current directory"
elif [[ "$1" == "dir" ]] || [[ "$1" == "-dir" ]]; then
 directories=$2
 echo "checking directory $2"
elif [[ "$1" == "asarray" ]]; then
 ndir=$(cat $2 | wc -l)
 cp ~/git/DeYonker-lab-scripts/CM_MD_to_QM_project/1-checkjobs 1-checkjobs-neb
 sed -i "s/SETARRAY/1-$ndir/; s/SETLISTFILE/$2/" 1-checkjobs-neb
 sed -i "s/check_cm_jobs.sh/check_cm_jobs_neb_workflow.sh/g" 1-checkjobs-neb
 #sbatch 1-checkjobs
 exit
else
 directories=$(cat $1)
 echo "checking directories listed in file $1"
fi


wkdr=$(pwd) 
runningjobs=$(squeue --me -t running -r -o "%A" -h)
pendingjobs=$(squeue --me -t pending -r -o "%K_%j_%Z" -h)

for i in $(echo $directories); do
 echo $i
 cd $i
 # remove all old lists and 1-array files
 rm check_initialopt_*.txt check_product_*.txt check_neb-ts_*.txt check_tsfreq_*.txt 2> /dev/null
 rm check_pending.txt 2> /dev/null
 rm 1-array* 2> /dev/null
 for d in f*; do
  # if fxxxxx dir has an initialopt orca.out file, start the checks, otherwise move on to next dir (continue)
  if [ -f $d/orca.out ]; then 
    echo -ne "checking $i/$d \033[K\r"
    checkdirstate $d initialopt
  else 
    continue
  fi
  if [ -d $d/product ] && [ -f $d/product/orca.out ]; then checkdirstate $d/product product; fi
  if [ -d $d/neb-ts ] && [ -f $d/neb-ts/orca.out ]; then checkdirstate $d/neb-ts neb-ts; else continue; fi
 done
 # filter out pending jobs
 echo -ne "checking queue \033[K\r"
 for j in $(grep $(pwd)$ <<< $pendingjobs); do
  # $j from $pendingjobs in form arrayID_jobname_dir where arrayID = model number. this'll all break if you change job names to have underscores!
  jname=$(echo $j | awk -F_ '{print $2}' | sed "s/ORCA-//")
  if [[ "$jname" == "ORCAJOB" ]]; then jname="initialopt"; fi
  dname=$(echo $j | awk -F_ '{ printf("f%05d\n",$1) }')
  # check if this pending job is in a list other than running, if it is then make sure to remove from there so not restarted twice!
  if [[ $(grep -H $dname check_${jname}_*.txt | grep -v "running") ]]; then
   for k in $(grep -H $dname check_${jname}_*.txt | awk -F: '{print $1}'); do
    echo "dir $dname has pending $jname job, removing from list $k to avoid possible duplication" >> check_pending.txt
    sed -i "\#$dname#d" $k
   done
  else
   echo "dir $dname has pending $jname job, seems to be a new job not a restart" >> check_pending.txt
  fi
 done
 # finally remove any empty list files left over after their contents have been moved to other lists by the imagmode/ts exclusion/pending checks
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

