#!/bin/bash
# CEW 10/21/2013
# usage:
#
# check-opt.sh (arg1) where the valid arg1 is filename or --help
#

if [ "$1" = "--help" ]; then
echo "This checks for the lowest energy and best convergence criteria of an opt

check-opt.sh arg1 (which is \$1) arg2 (which is \"more\")
arg1 is the name of the an output file
arg2 is \"more\" if you desire more information
"
exit
fi

 if [ -z "$1" ] && [ -f 1.out ]; then
  file=1.out
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


# find out the line number to which to process with head
 top=`grep -n "Leave Link    1" $file | head -1 | sed 's%:% %g' | awk '{print $1}'`

 if [ -z "$top" ]; then
   top=`wc -l $file|awk '{print $1}'`
 fi

# get the route line
 route_line=`head -n $top $file |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \-\- ' /#/ {for (i=1; i<=NF; i++) print $i;} ' | sed 's/  //g' | grep "#"`

# process the routeline and get the scf maxcyc
 maxcyc=$((`echo $route_line| awk '{for(i=1;i<=NF;i++) print $i }'|\
 grep -i scf |\
 sed -e 's%(%,%g' -e 's%)%,%g' |\
 awk -F, '{for(i=1;i<=NF;i++) print $i }' |\
 grep maxcyc |\
 sed 's%=%\n%g' |\
 tail -1`+1))

if [ $maxcyc==1 ]; then
# the issue here is the default for scf maxcyc depeends upon if xqc is used, xqc gives maxcon=64 and maxcyc=128
maxcyc=128
fi

#printf "after  %3s cycles\n" $maxcyc
print_maxcyc="`printf "after  %3s cycles\n" $maxcyc`"
#echo "$print_maxcyc"

scfwarning="`grep ">>>>>>>>>> Convergence criterion not met" $file`"
#  xqcinput="`grep "Quadratic Convergence SCF Method." $file`"
xqcwarning="`grep "Quadratic Convergence SCF Method." $file`"
if [ -n "$scfwarning" ] && [ -n "$xqcwarning" ]; then
 echo "Warning, the SCF did not converge and using XQC!!!"
 echo "The SCF and Forces might not match up!!!"
elif [ -n "$scfwarning" ]; then
 echo "Warning, the SCF did not converge!!!"
fi

isxtboutput=`grep "xtb command was" "$file" | head -1`
isoniomoutputfile=`grep "ONIOM: extrapolated" "$file" | head -1`
istddft=`grep "Total Energy" "$file" | head -1`

if [ -n "$isoniomoutputfile" ]; then
 printf "%s " "$file" is a ONIOM Gaussian output file

# process the routeline and get the ONIOM low-layer method (won't work if high-layer and low-layer methods are the same)
 oniom_low_layer=`echo $route_line| awk '{for(i=1;i<=NF;i++) print $i }'| grep -i oniom | sed -e 's%.*:%%g' -e 's%/.*%%g' -e 's%)%%g'`
 printf "%s \n" "; the low-layer method is $oniom_low_layer"

      energies=( `grep "ONIOM: extrapolated"  $file | awk '{print $5}' ` )
       lowenergy=`grep "ONIOM: extrapolated"  $file | awk '{print $5}' |sort -n -r |tail -1`
  scf_energies=( `grep "SCF Done"             $file |egrep -i -v "$print_maxcyc|$oniom_low_layer" | awk '{print $5}' ` )


elif [ -n "$istddft" ]; then
 echo "$file" is a TDDFT Gaussian output file
      energies=( `grep "Total Energy"         $file | awk '{print $5}' ` )
       lowenergy=`grep "Total Energy"         $file | awk '{print $5}' |sort -n -r |tail -1`
  scf_energies=( `grep "SCF Done"             $file |grep -v "$print_maxcyc" | awk '{print $5}' ` )

elif [ -n "$isxtboutput" ]; then
 echo "$file" is a xtb to Gaussian output file
      energies=( `grep "NIter=  "         $file | awk '{print $2}' ` )
       lowenergy=`grep "NIter=  "         $file | awk '{print $2}' |sort -n -r |tail -1`
  scf_energies=( `grep "NIter=  "             $file |grep -v "$print_maxcyc" | awk '{print $2}' ` )

#normal output
else
  energies=( `grep "SCF Done"             $file |grep -v "$print_maxcyc" | awk '{print $5}' ` )
   lowenergy=`grep "SCF Done"             $file | awk '{print $5}' |sort -n -r |tail -1`
fi

#  energies=( `grep "SCF Done"             $file |grep -v "$print_maxcyc" | awk '{print $5}' ` )
 convcrita=( `grep "Maximum Force"        $file | awk '{print $3}' ` )
 convcritb=( `grep "RMS     Force"        $file | awk '{print $3}' ` )
 convcritc=( `grep "Maximum Displacement" $file | awk '{print $3}' ` )
 convcritd=( `grep "RMS     Displacement" $file | awk '{print $3}' ` )
lconvcrita=`grep "Maximum Force"        $file | awk '{print $3}' |grep -v "*" |sort -n -r |tail -1`
lconvcritb=`grep "RMS     Force"        $file | awk '{print $3}' |grep -v "*" |sort -n -r |tail -1`

if [ "$2" == "more" ]; then
 j=0
 for i in ${energies[@]}
  do
   j=`(expr $j + 1)`
   echo cycle $j energy is $i, Max Force is ${convcrita[j-1]}, and RMS Force is ${convcritb[j-1]}
  done
fi


if [ -n "$isoniomoutputfile" ]; then
# echo ONIOM stuff
 echo lowest ONIOM energy for $file was $lowenergy
 echo " energy for $file max force" `egrep "ONIOM: extrapolated|SCF Done|YES| NO " $file | grep -i -v $oniom_low_layer | egrep -B6 "Maximum Force            $lconvcrita" | egrep "ONIOM: extrapolated|SCF Done" | head -2| awk '{print $5}'`
 echo " energy for $file rms force" `egrep "ONIOM: extrapolated|SCF Done|YES| NO " $file | grep -i -v $oniom_low_layer | egrep -B7 "RMS     Force            $lconvcritb" | egrep "ONIOM: extrapolated|SCF Done" | head -2| awk '{print $5}'`

 echo smallest max force for $file was $lconvcrita
 echo smallest rms force for $file was $lconvcritb

 echo "
based upon smallest max force:"
 egrep "ONIOM: extrapolated|SCF Done|YES| NO " $file | grep -i -v $oniom_low_layer | egrep -B2 "Maximum Force            $lconvcrita" | grep -v Max
 egrep "ONIOM: extrapolated|SCF Done|YES| NO " $file | grep -i -v $oniom_low_layer | egrep -A3 "Maximum Force            $lconvcrita"

 echo "
based upon smallest rms force:"
 egrep "ONIOM: extrapolated|SCF Done|YES| NO " $file | grep -i -v $oniom_low_layer | egrep -B3 -A2 "RMS     Force            $lconvcritb"

 echo "
based upon lowest energy:"
egrep "ONIOM: extrapolated|SCF Done|YES| NO " $file | grep -i -v $oniom_low_layer | grep -A5 ""\\$lowenergy"" |grep -v "\-\-" #|tail -4

elif [ -n "$istddft" ]; then
 echo lowest TDDFT energy for $file was $lowenergy
 echo " energy for $file max force" `egrep "Total Energy|SCF Done|YES| NO " $file | egrep -B6 "Maximum Force            $lconvcrita" | egrep "Total Energy|SCF Done" | head -2| awk '{print $5}'`
 echo " energy for $file rms force" `egrep "Total Energy|SCF Done|YES| NO " $file | egrep -B7 "RMS     Force            $lconvcritb" | egrep "Total Energy|SCF Done" | head -2| awk '{print $5}'`

 echo smallest max force for $file was $lconvcrita
 echo smallest rms force for $file was $lconvcritb

 echo "
based upon smallest max force:"
 egrep "Total Energy|SCF Done|YES| NO " $file | egrep -B2 "Maximum Force            $lconvcrita" | grep -v Max
 egrep "Total Energy|SCF Done|YES| NO " $file | egrep -A3 "Maximum Force            $lconvcrita"

 echo "
based upon smallest rms force:"
 egrep "Total Energy|SCF Done|YES| NO " $file | egrep -B3 -A2 "RMS     Force            $lconvcritb"

 echo "
based upon lowest energy:"
egrep "Total Energy|SCF Done|YES| NO " $file | grep -A5 ""\\$lowenergy"" |grep -v "\-\-" #|tail -4

elif [ -n "$isxtboutput" ]; then
 echo lowest energy for $file was $lowenergy
 echo " energy for $file max force" `egrep "NIter=|YES| NO " $file | egrep -B6 "Maximum Force            $lconvcrita" | grep "NIter"| head -1| awk '{print $2}'`
 echo " energy for $file rms force" `egrep "NIter=|YES| NO " $file | egrep -B7 "RMS     Force            $lconvcritb" | grep "NIter"| head -1| awk '{print $2}'`

 echo smallest max force for $file was $lconvcrita
 echo smallest rms force for $file was $lconvcritb

 echo "
based upon smallest max force:"
 egrep "Step number|NIter=|YES| NO | Step number" $file | egrep -B2 "Maximum Force            $lconvcrita" | grep -v Max
 egrep "Step number|Niter=|YES| NO | Step number" $file | egrep -A2 "Maximum Force            $lconvcrita"

 echo "
based upon smallest rms force:"
 egrep "Step number|NIter=|YES| NO | Step number" $file | egrep -B3 "RMS     Force            $lconvcritb"

 echo "
based upon lowest energy:"
egrep "Step number|NIter=|YES| NO | Step number" $file | grep -A5 ""\\$lowenergy"" |grep -v "\-\-" #|tail -5

else
 echo lowest energy for $file was $lowenergy
 echo " energy for $file max force" `egrep "SCF Done|YES| NO " $file | egrep -B6 "Maximum Force            $lconvcrita" | grep "SCF Done"| head -1| awk '{print $5}'`
 echo " energy for $file rms force" `egrep "SCF Done|YES| NO " $file | egrep -B7 "RMS     Force            $lconvcritb" | grep "SCF Done"| head -1| awk '{print $5}'`

 echo smallest max force for $file was $lconvcrita
 echo smallest rms force for $file was $lconvcritb

 echo "
based upon smallest max force:"
 egrep "Step number|SCF Done|YES| NO | Step number" $file | egrep -B2 "Maximum Force            $lconvcrita" | grep -v Max
 egrep "Step number|SCF Done|YES| NO | Step number" $file | egrep -A2 "Maximum Force            $lconvcrita"

 echo "
based upon smallest rms force:"
 egrep "Step number|SCF Done|YES| NO | Step number" $file | egrep -B3 "RMS     Force            $lconvcritb"

 echo "
based upon lowest energy:"
egrep "Step number|SCF Done|YES| NO | Step number" $file | grep -A4 ""\\$lowenergy"" |grep -v "\-\-" #|tail -5

fi

