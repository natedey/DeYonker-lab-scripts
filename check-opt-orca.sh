#!/bin/bash
# DAW 2026/01/08
# usage:
# check-opt-orca.sh (arg1) where the valid arg1 is filename or --help
#

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
echo "This checks for the lowest energy and best convergence criteria of an opt
check-opt-orca.sh arg1
arg1 is the name of an output file, default is orca.out
"
exit
fi

 if [ -z "$1" ] && [ -f orca.out ]; then
  file=orca.out
 elif [ -n "$1" ] && [ -f "$1" ]; then
  file="$1"
 elif [ -n "$1" ]; then
  echo ""$1" does not exist"
  echo "use \"--help\" for the command line argument to get directions"
  exit
 else
  echo "no file to process"
  echo "use \"--help\" for the command line argument to get directions"
  exit
 fi

maxcycles=$(grep "Max. no of cycles        MaxIter" $file | awk '{print $NF}')
donecycles=$(grep "GEOMETRY OPTIMIZATION CYCLE" $file | tail -1 | awk '{print $5}')
lowenergy=$(grep "FINAL SINGLE POINT ENERGY" $file | awk '{print $NF}' |sort -n -r |tail -1)
lowmaxforce=$(grep " MAX gradient" $file | awk '{print $3}' |sort -n -r |tail -1)
lowrmsforce=$(grep " RMS gradient" $file | awk '{print $3}' |sort -n -r |tail -1)

echo "max number of geometry cycles for $file was $maxcycles"
echo "number of geometry cycles done in $file was $donecycles"
echo "lowest energy for $file was $lowenergy"
echo "smallest rms gradient for $file was $lowrmsforce"
echo "smallest max gradient for $file was $lowmaxforce"
echo ""
echo "based on smallest rms gradient:"
egrep 'GEOMETRY OPTIMIZATION CYCLE | observed energy change | RMS gradient | MAX gradient | RMS step | MAX step |FINAL SINGLE POINT ENERGY |FINAL ENERGY EVALUATION AT THE STATIONARY POINT' $file | grep -B 3 -A 3 "RMS gradient * $lowrmsforce"
echo ""
echo "based on smallest max gradient:"
egrep 'GEOMETRY OPTIMIZATION CYCLE | observed energy change | RMS gradient | MAX gradient | RMS step | MAX step |FINAL SINGLE POINT ENERGY |FINAL ENERGY EVALUATION AT THE STATIONARY POINT' $file | grep -B 4 -A 2 "MAX gradient * $lowmaxforce"
echo ""
echo "based on lowest energy:"
egrep 'GEOMETRY OPTIMIZATION CYCLE | observed energy change | RMS gradient | MAX gradient | RMS step | MAX step |FINAL SINGLE POINT ENERGY |FINAL ENERGY EVALUATION AT THE STATIONARY POINT' $file | grep -B 1 -A 5 "FINAL SINGLE POINT ENERGY * $lowenergy"
#echo ""
#echo "final cycle:"
#egrep 'GEOMETRY OPTIMIZATION CYCLE | observed energy change | RMS gradient | MAX gradient | RMS step | MAX step |FINAL SINGLE POINT ENERGY |FINAL ENERGY EVALUATION AT THE STATIONARY POINT' $file | grep -A 6 "GEOMETRY OPTIMIZATION CYCLE $donecycles"

