#!/bin/bash
# CEW

if [ "$1" = "--help" ]; then
echo "This script extracts the geometry for a given step in input format
extract-geom-input.sh step-number/energy filename
"
exit
fi

if [ -z "$1" ]; then
 echo you need to enter a step number or energy
 exit
else

  if [ -z "$2" ] && [ -f 1.out ]; then
   file=1.out
  elif [ -n "$2" ] && [ ! -f "$2" ]; then
   echo "$2" file does not exist
   exit
  elif [ -f "$2" ]; then
   isoutputfile=`head -1 "$2" | cut -f1 -d,`
   if [ "$isoutputfile" != " Entering Gaussian System" ]; then
    echo "$2" is not a Gaussian output file
    exit
   fi
   file="$2"
  else
   echo you need a filename as the second command-line argument
   exit
  fi
fi

 isoniomoutputfile=`grep "ONIOM: extrapolated" "$file" | head -1`

 if [ -n "$isoniomoutputfile" ]; then
  energy="extrapolated"
 else
  energy="SCF Done"
 fi

 number_D="`grep -c "Numerically estimating second derivatives" $file`"
  if [ $number_D -eq 0 ]; then
    number_D=0
  fi

 head_length=`grep -n "103.exe)" $file| head -1 | awk '{print $1}' | cut -f1 -d:`
# echo head_length is $head_length
 if [ -z $head_length ]; then
  echo exiting... the file terminated before a geometry was printed
  exit
 fi
 old_IFS=$IFS
### VERY IMPORTANT - changes break point for arrays!!! no break on spaces
 IFS=$'\n'

# molecular specification
# get this section with awk, then egrep out the lines that we don't want
 sec3=("`head -$head_length $file | awk '/^ Charge =/,/^ NAtoms= /||/Recover connectivity data from disk./||/Isotopes and Nuclear Properties/' | egrep -v "Redundant|Symbolic|Charge|NAtoms|Recover|Isotopes|Iteration|^[[:space:]]*$" | sed 's%,% %g'`")
ec_NF="`echo "$sec3" | awk '{print NF}' | head -1`"
 sec_SF="`echo "$sec3" | awk '{print $2}' | head -1 | grep -v "0."| egrep "0|-1"`"

 if [ "$sec_NF" -eq 5 ]; then
   if [ -n "$sec_SF" ]; then
#     echo there are 5 columns of data and the second column is an integer
    for item in ${sec3[*]}
    do
        freeze_codes=(${freeze_codes[@]} `echo $item | awk '{print $2}'`)
#        echo the freeze-code for $item is `echo $item | awk '{print $2}'`
    done
   else
    for item in ${sec3[*]}
    do
        layer_codes=(${layer_codes[@]} `echo $item | awk '{print $5}'`)
#        echo the layer code for $item is `echo $item | awk '{print $5}'`
    done
   fi
 elif [ "$sec_NF" -ge 6 ]; then
# echo there more are 5 columns of data
   for item in ${sec3[*]}
   do
#printf "%s\n" $item | awk '{printf "%-5s%5s%15.10f%15.10f%15.10f\n", $1, $2, $3, $4, $5}' >> $output.xyz
       freeze_codes=(${freeze_codes[@]} `echo $item | awk '{print $2}'`)
       layer_codes=(${layer_codes[@]} `echo $item | awk '{print $6}'`)
       if [ "`echo $item | awk '{print NF}'`" -ge 7 ]; then
         sub_codes=(${sub_codes[@]} `echo $item | awk '{print $7}'`)
#         echo the sub code is `echo $item | awk '{print $7}'`
       else
         sub_codes=(${sub_codes[@]} " ")
       fi
#       printf "%s\n" $item | awk '{print $2, $6}'
   done
 fi

IFS=$old_IFS

 stepnumber=$1

 valid_step="`echo $stepnumber | egrep ^[[:digit:]]+$`"
# echo valid_step is $valid_step
 if [ "$stepnumber" == "0" ]; then
   echo arg1: $stepnumber\; first command line argument needs to be first, last, a whole number, or an energy to be valid
   exit
 elif [ "$stepnumber" != "first" ] && [ "$stepnumber" != "last" ] && [ "$valid_step" = "" ]; then
  if [ -z "`grep "$energy" $file | grep -- $stepnumber`" ]; then
   echo arg1: $stepnumber\; first command line argument needs to be first, last, a whole number, or an energy to be valid
   exit
  fi
 fi

#natoms=$(expr `grep -i NAtoms $file | head -n 1 | awk ' {print $2} '`)
natoms=$((`grep -i NAtoms $file | head -n 1 | awk ' {print $2} '`))
 if [ "$natoms" -eq 0 ]; then
 # echo the number of atoms is empty, trying again...
  natoms=$((`grep "Using compressed storage, NAtomX" $file | head -n 1 | awk ' {print $5} ' |sed 's%.$%%g'`))
  if [ "$natoms" -eq 0 ]; then
   echo the number of atoms is still empty
   exit
  fi
 fi
nlines=$(($natoms + 5))

jobsteps=`grep -c "Normal termination" $file`
stdorientation=`grep -c "Standard orientation:" $file`

if [ "$stdorientation" -eq "0" ];then
 orientation=Input
else
 orientation=Standard
fi

if [ $jobsteps == "2" ]; then
 firststepln=`grep -n "Normal termination" $file | head -1 | cut -f1 -d:`
 totalnumbersteps=$((`grep -c "Step number" $file`-1))
 if [ -n "$valid_step" ]; then
# orientationln=(`grep -n "$orientation orientation:" $file | cut -f1 -d:`)
 orientationln=(`grep -n "$orientation orientation:" $file | awk 'NR>'"$number_D"'{print}'| cut -f1 -d:`)
  stepnumberln=(`grep -n "Step number" $file | cut -f1 -d:`)
  if [ "$stepnumber" != "first" ] && [ "$stepnumber" != "last" ]; then
   if [ "$stepnumber" -gt "$totalnumbersteps" ]; then
    echo you requested a step that does not exist
    echo there are only $totalnumbersteps steps in $file
    exit
   fi
  fi
 else
 orientationln=(`egrep -n "$energy|orientation:" $file | grep -B2 -- "$stepnumber" | grep "orientation:" | tail -1 | cut -f1 -d:`)
  stepnumberln=(`grep -n -- "$stepnumber" $file |head -1 | cut -f1 -d:`)
 fi


elif [ $jobsteps == "1" ] || [ $jobsteps == "0" ]; then
 firststepln=`grep -n "Normal termination" $file | head -1 | cut -f1 -d:`
 totalnumbersteps=$((`grep -c "Step number" $file`))
 if [ -n "$valid_step" ]; then
# orientationln=(`grep -n "$orientation orientation:" $file | cut -f1 -d:`)
 orientationln=(`grep -n "$orientation orientation:" $file | awk 'NR>'"$number_D"'{print}'| cut -f1 -d:`)
  stepnumberln=(`grep -n "Step number" $file | cut -f1 -d:`)
  if [ "$stepnumber" != "first" ] && [ "$stepnumber" != "last" ]; then
   if [ "$stepnumber" -gt "$totalnumbersteps" ]; then
    echo you requested a step that does not exist
    echo there are only $totalnumbersteps steps in $file
    exit
   fi
  fi
 else
 orientationln=(`egrep -n "$energy|orientation:" $file | grep -B2 -- "$stepnumber" | grep "orientation:" | tail -1 | cut -f1 -d:`)
  stepnumberln=(`grep -n -- "$stepnumber" $file |head -1 | cut -f1 -d:`)

 fi

else
 echo $file has too many linked jobs, are you sure this is an opt or opt+freq?
exit
fi

# get the part of the output file that you need and then trim the output
#awk "NR==1346,NR==1541" $file |head -$nlines |tail -$natoms
if [ "$stepnumber" == "first" ]; then
  echo "first step from $file
"
  atom_coords=(`grep -A $nlines "$orientation orientation:" $file |head -n $nlines |tail -n $natoms | awk '{print $2,$4,$5,$6}'`)
elif [ "$stepnumber" == "last" ]; then
  echo "last step from $file
"
  atom_coords=(`grep -A $(($nlines-1)) "$orientation orientation:" $file |tail -n $natoms | awk '{print $2,$4,$5,$6}'`)
elif [ -n "$valid_step" ]; then
  echo "step number $stepnumber from $file
"
   if [ "${stepnumberln[$((stepnumber-1))]}" == "" ]; then
    last_line=last
   else
    last_line=${stepnumberln[$((stepnumber-1))]}
   fi
  atom_coords=(`awk 'NR=='"${orientationln[$((stepnumber-1))]}"',NR=='"$last_line"'' $file |head -$nlines |tail -$natoms | awk '{print $2,$4,$5,$6}'`)
else
  echo "energy $stepnumber from $file
"
  atom_coords=(`awk 'NR=='"$orientationln"',NR=='"$stepnumberln"'' $file |head -$nlines |tail -$natoms | awk '{print $2,$4,$5,$6}'`)
fi

 if [ -n "$isoniomoutputfile" ]; then
  echo `grep "Charge =" $file |head -1 |awk '{print $3,$6}'` `grep "Charge =" $file | head -2 | tail -1 |awk '{print $3,$6}'` `grep "Charge =" $file |tail -1 |awk '{print $3,$6}'`
 else
  echo `grep "Charge =" $file |tail -n 1 |awk '{print $3,$6}'`
 fi

#put the coordinates into an array (atom_coords), then printf array with freeze-codes
 if [ $sec_NF -ge 6 ]; then
 k=0
   for (( i = 0 ; i < ${#atom_coords[*]} ; i++ ))
   do
       printf " %s" ${atom_coords[i]} ${freeze_codes[k]} ${atom_coords[i+1]} ${atom_coords[i+2]} ${atom_coords[i+3]} ${layer_codes[k]} ${sub_codes[k]}|  awk '{printf "%-5s%5s%15.10f%15.10f%15.10f%5s%5s\n", $1, $2, $3, $4, $5, $6, $7}'
#       printf "\n"
       i=$i+3
       k=$k+1
   done

 elif [ "$sec_NF" -eq 5 ]; then
  if [ -n "$sec_SF" ]; then
   k=0
   for (( i = 0 ; i < ${#atom_coords[*]} ; i++ ))
   do
       printf " %s" ${atom_coords[i]} ${freeze_codes[k]} ${atom_coords[i+1]} ${atom_coords[i+2]} ${atom_coords[i+3]} | awk '{printf "%-5s%5s%15.10f%15.10f%15.10f\n", $1, $2, $3, $4, $5}'
#       printf "\n"
       i=$i+3
       k=$k+1
   done
  else
   k=0
   for (( i = 0 ; i < ${#atom_coords[*]} ; i++ ))
   do
       printf " %s" ${atom_coords[i]} ${atom_coords[i+1]} ${atom_coords[i+2]} ${atom_coords[i+3]} ${layer_codes[k]}| awk '{printf "%-5s%15.10f%15.10f%15.10f%5s\n", $1, $2, $3, $4, $5}'
#       printf "\n"
       i=$i+3
       k=$k+1
   done
  fi
 elif [ "$sec_NF" -eq 4 ]; then
   for (( i = 0 ; i < ${#atom_coords[*]} ; i++ ))
   do
#       printf " %s" ${atom_coords[i]} ${atom_coords[i+1]} ${atom_coords[i+2]} ${atom_coords[i+3]} | awk '{printf "%-5s%15.10f%15.10f%15.10f\n", $1, $2, $3, $4}'
       printf " %s" ${atom_coords[i]} ${atom_coords[i+1]} ${atom_coords[i+2]} ${atom_coords[i+3]} | awk '{printf "%-6s%14s%15s%15s\n", $1, $2, $3, $4}'
       i=$i+3
   done
# need to print anyway, even if there was a Z-matrix in the input file (sec_NF would be = 1)
 else
   for (( i = 0 ; i < ${#atom_coords[*]} ; i++ ))
   do
       printf " %s" ${atom_coords[i]} ${atom_coords[i+1]} ${atom_coords[i+2]} ${atom_coords[i+3]} | awk '{printf "%-6s%14s%15s%15s\n", $1, $2, $3, $4}'
       i=$i+3
   done
 fi

