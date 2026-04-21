#!/bin/bash

if [ -z "$1" ]; then
 directories="."
else
 directories=$(cat $1)
fi
wkdir=$(pwd)

totdirs=0
totexcluded=0
totdone=0
totlayer1=0
totlayer2=0
totlayer3=0

for i in $(echo $directories); do
  cd $i
  if [[ "$i" == "." ]]; then dirname=$(pwd | awk -F/ '{print $NF}'); else dirname=$i; fi
  Ndirs=$(ls -d f* | wc -l)
  if [ -f check_tsopt_excluded.txt ]; then Nexcluded=$(cat check_tsopt_excluded.txt | wc -l); else Nexcluded=0; fi
  Ndone=$(cat check_tsopt_done.txt | wc -l)
  layer1=0
  layer2=0
  layer3=0
  for i in $(awk -F/ '{print $1}' check_tsopt_done.txt); do
   if [ -d $i/original-tsguess-tsconstrained ] && [ -d $i/original-tsguess-tsopt ] && [ -d $i/tsopt-failed ]; then
     layer3=$(( layer3 + 1 ))
   elif [ -d $i/original-tsguess-tsconstrained ] && [ -d $i/original-tsguess-tsopt ]; then
     layer2=$(( layer2 + 1 ))
   else
     layer1=$(( layer1 + 1 ))
   fi
  done
  echo "directory $dirname: $Ndirs models / $Ndone tsopts done = $layer1 normal + $layer2 new guess + $layer3 direct tsopt / $Nexcluded excluded"
  cd $wkdir
  totdirs=$(( totdirs + Ndirs ))
  totexcluded=$(( totexcluded + Nexcluded ))
  totdone=$(( totdone + Ndone ))
  totlayer1=$(( totlayer1 + layer1 ))
  totlayer2=$(( totlayer2 + layer2 ))
  totlayer3=$(( totlayer3 + layer3 ))
done

if [[ "$directories" != "." ]]; then
  echo "$totdirs models / $totdone tsopts done = $totlayer1 normal + $totlayer2 new guess + $totlayer3 direct tsopt / $totexcluded excluded"
fi
