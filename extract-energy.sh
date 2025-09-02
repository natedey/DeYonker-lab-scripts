#!/bin/bash
# CEW

if [ "$1" = "--help" ]; then
echo "This script extracts the energy data from SCF, opt, and opt+freq output GXX file
extract-energy.sh filename
"
exit
fi

if [ -z "$1" ] && [ -f 1.out ]; then
 file=1.out
elif [ -n "$1" ] && [ ! -f "$1" ]; then
 echo "$1" file does not exist
 exit
elif [ -f "$1" ]; then
 isoutputfile=`head -1 "$1" | cut -f1 -d,`
 if [ "$isoutputfile" != " Entering Gaussian System" ]; then
  echo "$1" is not a Gaussian output file
  exit
 fi
 file="$1"
else
 echo you need a filename as the first command-line argument
 exit
fi

isnormaloutputfile=`tail -1 $file |awk '{print $1, $2}'`
if [ "$isnormaloutputfile" != "Normal termination" ]; then
 echo $file failed to terminate properly
 exit
fi

isoniomoutputfile=`grep "ONIOM: extrapolated" "$file" | head -1`

if [ -n "$isoniomoutputfile" ]; then
 el_energy=`grep "ONIOM: extrapolated energy" "$file" | tail -1 | awk '{print $5}'`
else
 el_energy=`grep "SCF Done" "$file" | tail -1 | awk '{print $5}'`
fi


sum_energy=(`grep "Sum of e" "$file" | awk '{print $NF}'`)

conv_criteria=(`egrep "Maximum Force|RMS     Force|Maximum Displacement|RMS     Displacement" $file |tail -4 |awk '{print $5}'`)
   conv_value=(`egrep "Maximum Force|RMS     Force|Maximum Displacement|RMS     Displacement" $file |tail -4 |awk '{print $3}'`)

printf "    el energy= %s\n" $el_energy

if [ -n "${sum_energy[0]}" ]; then
 printf "          zpe= %s\n" ${sum_energy[0]}
 printf "    th energy= %s\n" ${sum_energy[1]}
 printf "  th enthalpy= %s\n" ${sum_energy[2]}
 printf "  free energy= %s\n" ${sum_energy[3]}
fi

printf "   %s      %s      %s      %s\n" ${conv_criteria[0]} ${conv_criteria[1]} ${conv_criteria[2]} ${conv_criteria[3]}
printf "%s %s %s %s\n" ${conv_value[0]} ${conv_value[1]} ${conv_value[2]} ${conv_value[3]}
