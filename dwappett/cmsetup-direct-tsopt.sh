#!/bin/bash
# script to set up direct ts opts for CM MD->QM project
# created DAW Feb 2026
# usage: cmsetup-direct-tsopt.sh [list file]

if [ -z "$1" ]; then
  echo "this script needs to be given a file listing directories!"
  exit
elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  echo "
usage: cmsetup-direct-tsopt.sh [list]
this script moves the existing tsopt directory to tsopt-failed, then sets up a new optts job on the tsguess.pdb structure
this should only be used if the post-tsconstrained tsopt has totally failed (or I guess maybe if the tsconstrained has failed?)

the automated check_tsopt_[not-done].txt lists do not distinguish whether a tsopt is currently stuck at the normal first try/direct opt/new guess
and this script does not skip already set up directories like the original cmsetup-tsopt does!!!
to be safe, please prepare the list BY HAND, FROM SCRATCH, EVERY TIME!
"
  exit
elif grep -q -e 'initialopt' -e 'irc1' -e 'irc2' <<< $1; then
  echo "you should not be trying to use this script with an initialopt/irc1/irc2 list!"
  exit
elif [[ "$1" == "check_tsopt_"* || "$1" == "check_tsconstrained_"* ]]; then
  echo "
  looks like you've provided one of the standard automated check_cm_jobs.sh output lists which is not recommended.
  those lists do not distinguish whether a tsopt is currently stuck at the normal first try/direct opt/new guess
  and this script does not skip already set up directories like the original cmsetup-tsopt does!!!
  direct optimisation of the tsguess should only be tried when all the normal steps have failed, but before a new guess.
  enter Y to continue with list $1 or anything else to cancel"
  read altlist
  if [[ "${altlist,,}" == "y" ]]; then
    echo "continuing with list $1"
  else
    exit
  fi
fi

wkdr=$(pwd)
joblist="none"
warn="please double check dirs that did not have existing tsopt subdirs:"
for i in $(awk '{print $1}' $1); do
  d=$(echo $i | awk -F/ '{print $1}')
  cd $d
  if [ -d "tsopt" ]; then
    echo $d
    mv tsopt tsopt-failed
    mkdir tsopt
    # get first propagated inp if there is one, otherwise orca.inp
    if [ -f "tsconstrained/1-"*"-inp" ]; then
     cp tsconstrained/1-*-inp tsopt/orca.inp
    else
     cp tsconstrained/orca.inp tsopt
    fi
    cp tsconstrained/tsguess.pdb tsopt
    if [ -f "tsconstrained/altts-newguess.txt" ]; then cp tsconstrained/altts-newguess.txt tsopt; fi
    cd tsopt
    sed -i "s/ opt / optts /; /  { B /d" orca.inp
    if grep -q "product bond" ../tsconstrained/orca.inp && grep -q "reactant bond" ../tsconstrained/orca.inp; then
      b1=$(grep "product bond" ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
      b2=$(grep "reactant bond" ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
      sed -i "s/%geom/%geom\n  modify_internal\n$b1\n$b2\n  end/" orca.inp
    else
      bonds=$(grep " { B " ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
      sed -i "s/%geom/%geom\n  modify_internal\n${bonds//$'\n'/\\n}\n  end/" orca.inp
    fi
    if [[ "$joblist" == "none" ]]; then
      joblist=$((10#${d#f}))
    else
      joblist=$joblist","$((10#${d#f}))
    fi
    touch "altts-directopt.txt"
    cd $wkdr
  elif [ -d "tsconstrained" ]; then
    echo "$d - no existing tsopt but still setting up direct opt"
    warn="$warn $d"
    mkdir tsopt
    # get first propagated inp if there is one, otherwise orca.inp
    if [ -f "tsconstrained/1-"*"-inp" ]; then
     cp tsconstrained/1-*-inp tsopt/orca.inp
    else
     cp tsconstrained/orca.inp tsopt
    fi
    cp tsconstrained/tsguess.pdb tsopt
    if [ -f "tsconstrained/altts-newguess.txt" ]; then cp tsconstrained/altts-newguess.txt tsopt; fi
    cd tsopt
    sed -i "s/ opt / optts /; /  { B /d" orca.inp
    if grep -q "product bond" ../tsconstrained/orca.inp && grep -q "reactant bond" ../tsconstrained/orca.inp; then
      b1=$(grep "product bond" ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
      b2=$(grep "reactant bond" ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
      sed -i "s/%geom/%geom\n  modify_internal\n$b1\n$b2\n  end/" orca.inp
    else
      bonds=$(grep " { B " ../tsconstrained/orca.inp | sed "s/ C }/ A }/")
      sed -i "s/%geom/%geom\n  modify_internal\n${bonds//$'\n'/\\n}\n  end/" orca.inp
    fi
    if [[ "$joblist" == "none" ]]; then
      joblist=$((10#${d#f}))
    else
      joblist=$joblist","$((10#${d#f}))
    fi
    touch "altts-directopt.txt"
    cd ..
    mv tsconstrained tsconstrained-failed
    cd $wkdr
  else
    echo "$d - skipping because no tsopt or tsconstrained directories"
    cd $wkdr
    continue
  fi
done

cp ~/git/DeYonker-lab-scripts/dwappett/1-array-tsopt 1-array-direct-tsopt
sed -i "s/ASTART-AEND\%1/${joblist}%4/" 1-array-direct-tsopt
echo ""
echo "created 1-array-direct-tsopt"
if [[ "$warn" == *" f"* ]]; then echo "before running, $warn"; fi

