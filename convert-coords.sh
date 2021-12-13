#!/bin/bash
# CEW 2/14/2011
#
# description:
# this script takes a list of files in coords format (which are in coords format)
# and print out information in a format more friendly for supporting material
#
# usage:
# convert-coords.sh arg1 (arg2)
# where arg1 is the list of the files (which are in coords format)
# where arg2 is the list of the new names to use for the list of files
# the number of items in arg1 and arg2 must be the same

debug=1

if [ "$1" = "--help" ]; then
echo "This script takes a list of files (which are in coords format) and
print out information in a format more friendly for supporting material

The script can convert the \"names\" from the arg1 list to new \"names\"
or \"numbers\"; the script can take a list of the \"new names\" to use
for the list of files in the arg1 list

convert-coords.sh arg1 (arg2)
where arg1 is the list of the files (which are in coords format)
where arg2 is the list of the new names to use for the list of files
the number of items in arg1 and arg2 must be the same
"

else

echo "use --help for the command line argument to get directions
"

#test for one argument and no second argument
if [ -z "$1" ] && [ -z "$2" ]; then
echo "you need at least one more command-line argument
arg1 is the list of the files (which are in coords format)
arg2 is the list of the new names to use for the list of files
the number of items in arg1 and arg2 must be the same
"
elif [ -n "$1" ] && [ -z "$2" ]; then
echo "collecting data from `pwd`
using filenames from: $1
"
 if [ -f "$1" ]; then
  coordsfiles=( `cat $1` )
 else
  echo $1 file does not exist
 exit
 fi
elif [ -n "$1" ] && [ "$2" == "single" ]; then
#elif [ "$2" == "single" ]; then
echo "converting coords from only a single file named $1
"
 if [ -f "$1" ]; then
  coordsfiles=( $1 )
 else
  echo $1 file does not exist
 exit
 fi
elif [ -n "$1" ] && [ -n "$2" ]; then
echo "collecting data from `pwd`
using filenames from $1
using new names from $2
"
 if [ -f "$1" ] && [ -f "$2" ] ; then
  coordsfiles=( `cat $1` )
  nombrefiles=( `cat $2` )
 elif [ ! -f "$1" ]; then
  echo $1 file does not exist
  exit
 else
  echo $2 file does not exist
 exit
 fi
 if [ ${#coordsfiles[*]} != $((${#nombrefiles[*]})) ]; then
  echo ${#coordsfiles[*]}
  echo ${#nombrefiles[*]}
  echo "the number of items in $1 and $2 are different"
  exit
 fi
else
 echo the combination of command line arguments does not fit the logic of the script
fi

#for (( i = 0 ; i < ${#coordsfiles[@]} ; i++ ))
k=-1
for i in "${coordsfiles[@]}"
do
k=$(($k+1))
if [ ! -f $i ]; then
 echo $i coords file does not exist
 exit
fi

if [ "$2" != "single" ]; then
 if [ -n "$2" ]; then
  if [ $debug == 1 ]; then
   echo $i
  fi
  echo "${nombrefiles[$k]}"
 else
  echo $i
 fi
fi

awk 'BEGIN{
at_symbol[1]="H"
at_symbol[2]="He"
at_symbol[3]="Li"
at_symbol[4]="Be"
at_symbol[5]="B"
at_symbol[6]="C"
at_symbol[7]="N"
at_symbol[8]="O"
at_symbol[9]="F"
at_symbol[10]="Ne"
at_symbol[11]="Na"
at_symbol[12]="Mg"
at_symbol[13]="Al"
at_symbol[14]="Si"
at_symbol[15]="P"
at_symbol[16]="S"
at_symbol[17]="Cl"
at_symbol[18]="Ar"
at_symbol[19]="K"
at_symbol[20]="Ca"
at_symbol[21]="Sc"
at_symbol[22]="Ti"
at_symbol[23]="V"
at_symbol[24]="Cr"
at_symbol[25]="Mn"
at_symbol[26]="Fe"
at_symbol[27]="Co"
at_symbol[28]="Ni"
at_symbol[29]="Cu"
at_symbol[30]="Zn"
at_symbol[31]="Ga"
at_symbol[32]="Ge"
at_symbol[33]="As"
at_symbol[34]="Se"
at_symbol[35]="Br"
at_symbol[36]="Kr"
at_symbol[37]="Rb"
at_symbol[38]="Sr"
at_symbol[39]="Y"
at_symbol[40]="Zr"
at_symbol[41]="Nb"
at_symbol[42]="Mo"
at_symbol[43]="Tc"
at_symbol[44]="Ru"
at_symbol[45]="Rh"
at_symbol[46]="Pd"
at_symbol[47]="Ag"
at_symbol[48]="Cd"
at_symbol[50]="Sn"
at_symbol[51]="Sb"
at_symbol[53]="I"
at_symbol[54]="Xe"
at_symbol[55]="Cs"
at_symbol[56]="Ba"
at_symbol[72]="Hf"
at_symbol[73]="Ta"
at_symbol[74]="W"
at_symbol[75]="Re"
at_symbol[76]="Os"
at_symbol[77]="Ir"
at_symbol[78]="Pt"
at_symbol[79]="Au"
at_symbol[80]="Hg"
at_symbol[81]="Tl"
at_symbol[82]="Pb"
}
NR==1,/el energy=/ {
   if (NF=6) {
         printf "%-4s%10s%10s%10s\n", at_symbol[$2], $4, $5, $6
         }
      }
END{}' $i |grep -v "^[[:space:]]*$"
egrep "el energy=|zpe=|th energy=|th enthalpy=|free energy=" $i
printf "\n"
done

fi
