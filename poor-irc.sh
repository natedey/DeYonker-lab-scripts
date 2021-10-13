#!/bin/bash
# CEW 04/19/2013
# usage:
#
# poor-irc.sh arg1 (arg2)
#
## the script will build inputs for poor man's IRC form a completed TS freq
#
# poor-irc.sh arg1 (arg2)
# where arg1 is the output file name
# arg2 is the optional scale factor
#
# known issues:
# 1) the pertub array gets overpopulated with data from molecules with less than 6 atoms
# 2) ONIOM input building will only work with ONIOM(QM:semiempirical QM) or
#    ONIOM(QM:QM)
# 3) g03 frozen atoms has to be obtained from geom in the beginning of the output file
# awk -f /home/webster/bin/prog-freq-coords.awk 1.out | sed 's%,0,%  0  %g' | sed 's%,-1,% -1  %g'|awk '{printf "%3s \n", $2}'
# already have the code written to implement getting these frozen atoms in other scripts, will add it later

debug=0
printlevel=0
bindir=newbin
script_name=poor-irc

if [ "$1" = "--help" ]; then
echo "This script
 1) reads imaginary frequency displacement data from GXX output files
 2) builds input files for poor man's IRC into \$irc_pos/1.inp and \$irc_neg/1.inp

usage:
$ $script_name.sh arg1 (arg2)
where arg1 is the output file name
and arg2 is the optional scale factor (1.0 is the default)

make sure that you run it on a frequency calc, not just an opt+freq
use cleanfreq.sh to get the file

you also need \$template_input (and \$template_basis) files (the same as
those files used by the car script)
**if you do not supply a template.inp**
**then the script will use 1.inp for template.inp and template.basis**

if the output is from an ONIOM jobs, you also need \$oniom_data file
(which contains the ONIOM data at the end of each line in the molecular
specification section in the input file)

if there are two imag freqs and you want to use the smaller of the two imag freqs,
set \$sosp to true in the config file
if there are three imag freqs and you want to use the third imag freq,
set \$tosp to true in the config file

run \"$script_name.sh --config\" to print a reasonable $script_name.config file
run \"$script_name.sh --template\" to print reasonable template files (that must be edited)

set and export \$SCRIPT_CONFIG_LOC variable to set a location for $script_name.config
e.g., to use a config file in the current pirectory, issue
export SCRIPT_CONFIG_LOC=.
"

if [ -n "$SCRIPT_CONFIG_LOC" ]; then
 echo "\$SCRIPT_CONFIG_LOC is currently set to:
$SCRIPT_CONFIG_LOC"
else
 echo "\$SCRIPT_CONFIG_LOC is not set"
fi

exit
elif [ "$1" = "--config" ]; then
echo "# here is the default config file for $script_name.sh
# if it exists, it should be named ~/$bindir/$script_name.config
#
## flag:scale the value to use for the scaling the atomic displacements
scale 1.0
#
## flag:build whether to build input files (true/false)
build true
#build false
#
## flags:irc_pos/irc_neg subdirectory in which to build irc input files
irc_pos irc1
irc_neg irc2
#
## flag:template_location the directory location of the template files
template_location `pwd`
#
## flag:template_input the input template filename
template_input template.inp
#
## flag:template_basis the basis set template filename
template_basis template.bs
#
## flags:template_location_input/template_location_basis
## the template locations are all customizable
## these locations override the template_location
#template_location_input `pwd`
#template_location_basis `pwd`
#
## flag:oniom_data the oniom data filename
#oniom_data oniom-data.txt
#
## flag:sosp whether to use the pertubations of the smaller imag freq (true/false)
#sosp true
#sosp false
#
## flag:tosp whether to use the pertubations of the third imag freq (true/false)
#tosp true
#tosp false
#
## to comment out a flag, add a # before the flag
## to use the flag, remove the # before the flag
"
exit
elif [ "$1" = "--template" ] || [ "$1" = "--templates" ]; then
echo "Be sure to pay close attention to the newlines!
# here is a reasonable default template.inp
!begin
%chk=1.chk
%mem=800mw
%nproc=16
#P b3lyp/genecp opt freq gfinput scf=(xqc,maxcon=128,maxcyc=128)

! end"
echo "
# here is a reasonable default template.bs
!begin
Zn 0
lanl2dz
 ****
H C O 0
6-31G(d')
 ****

Zn
lanl2dz

! end"
exit
#end check for --help
fi

if [ -n "$SCRIPT_CONFIG_LOC" ]; then
 if [ ! -f $SCRIPT_CONFIG_LOC/$script_name.config ]; then
  echo you requested to use \$SCRIPT_CONFIG_LOC, but $SCRIPT_CONFIG_LOC/$script_name.config does not exist
  exit
 fi
fi

if [ -f $SCRIPT_CONFIG_LOC/$script_name.config ]; then
 echo using non-default config file: $SCRIPT_CONFIG_LOC/$script_name.config
 echo to stop using this non-default config file issue \"unset SCRIPT_CONFIG_LOC\"
 config="$SCRIPT_CONFIG_LOC/$script_name.config"

  scale="`grep ^scale   $config | awk '{print $2}'`"
  build="`grep ^build   $config | awk '{print $2}'`"
irc_pos="`grep ^irc_pos $config | awk '{print $2}'`"
irc_neg="`grep ^irc_neg $config | awk '{print $2}'`"

 template_location="`grep ^template_location $config | awk '{print $2}'`"
    template_input="`grep ^template_input    $config | awk '{print $2}'`"
    template_basis="`grep ^template_basis    $config | awk '{print $2}'`"

  template_location_input="`grep ^template_location_input $config | awk '{print $2}'`"
  template_location_basis="`grep ^template_location_basis $config | awk '{print $2}'`"

  oniom_data="`grep ^oniom_data $config | awk '{print $2}'`"
  sosp="`grep ^sosp $config | awk '{print $2}'`"
  tosp="`grep ^tosp $config | awk '{print $2}'`"

elif [ -f "`pwd`/$script_name.config" ]; then
 config="`pwd`/$script_name.config"
 echo "a local config file was found, be careful, using $config for configuration"

  scale="`grep ^scale   $config | awk '{print $2}'`"
  build="`grep ^build   $config | awk '{print $2}'`"
irc_pos="`grep ^irc_pos $config | awk '{print $2}'`"
irc_neg="`grep ^irc_neg $config | awk '{print $2}'`"

 template_location="`grep ^template_location $config | awk '{print $2}'`"
    template_input="`grep ^template_input    $config | awk '{print $2}'`"
    template_basis="`grep ^template_basis    $config | awk '{print $2}'`"

  template_location_input="`grep ^template_location_input $config | awk '{print $2}'`"
  template_location_basis="`grep ^template_location_basis $config | awk '{print $2}'`"

  oniom_data="`grep ^oniom_data $config | awk '{print $2}'`"
  sosp="`grep ^sosp $config | awk '{print $2}'`"
  tosp="`grep ^tosp $config | awk '{print $2}'`"

elif [ -f ~/$bindir/$script_name.config ]; then
 config="/home/$USER/$bindir/$script_name.config"
 echo "a default config file was found in ~/$bindir"

  scale="`grep ^scale   $config | awk '{print $2}'`"
  build="`grep ^build   $config | awk '{print $2}'`"
irc_pos="`grep ^irc_pos $config | awk '{print $2}'`"
irc_neg="`grep ^irc_neg $config | awk '{print $2}'`"

 template_location="`grep ^template_location $config | awk '{print $2}'`"
    template_input="`grep ^template_input    $config | awk '{print $2}'`"
    template_basis="`grep ^template_basis    $config | awk '{print $2}'`"

  template_location_input="`grep ^template_location_input $config | awk '{print $2}'`"
  template_location_basis="`grep ^template_location_basis $config | awk '{print $2}'`"

  oniom_data="`grep ^oniom_data $config | awk '{print $2}'`"
  sosp="`grep ^sosp $config | awk '{print $2}'`"
  tosp="`grep ^tosp $config | awk '{print $2}'`"

else
 echo "no config file was found, be careful, using reasonable defaults"
 #
 ## the value to use for the scaling the atomic displacements
 scale=1.0
 #
 ## whether to build input files (true/false)
 build=true
 #
 ## the directory location of the irc input files
 irc_pos=irc1
 irc_neg=irc2
 #
 ## the default template location
 template_location="`pwd`/"
 #
 ## the input template filename
 template_input=template.inp
 #
 ## the basis set template filename
 template_basis=template.bs
 #
 ## the template locations are all customizable
 #template_location_input=$template_location
 #template_location_basis=$template_location
 #
 ## the oniom_data file
 oniom_data=oniom-data.txt
 #
 ## flag:sosp whether to use the pertubations of the smaller imag freq (true/false)
 sosp=false
 ## flag:tosp whether to use the pertubations of the third imag freq (true/false)
 tosp=false
 #
fi

if [ -z "$sosp" ]; then
 sosp=false
fi

if [ -z "$tosp" ]; then
 tosp=false
fi

if [ -n "$2" ]; then
 scale=$2
 echo using scale: $scale from second command line argument
else
 echo using default scale: $scale
fi


# be sure that $template_location ends in a "/"
#[[ $template_location != */ ]] && template_location="$template_location"/

if [ "$build" == "false" ]; then
 echo "building input files is OFF
turn it on by setting the build flag to true in the config file
"
elif [ "$build" == "true" ]; then
 echo "building input files is ON
turn it on by setting the build flag to false in the config file
"
fi

if [ -z "$1" ]; then
 file=1.out
 echo using $file for output file
else
 file=$1
fi

if [ ! -f $file ]; then
echo $file does not exist, exiting...
exit
fi

# if not a gaussian file, don't process it
isoutputfile=`head -1 $file | cut -f1 -d,`
if [ "$isoutputfile" != " Entering Gaussian System" ]; then
 echo this is not a Gaussian output file
 exit
fi

if [ -n "`grep l101.exe $file | head -1 | grep g03`" ]; then
 version=g03
 echo This output is from G03
elif [ -n "`grep l101.exe $file | head -1 | grep g09`" ]; then
 version=g09
 echo This output is from G09
elif [ -n "`grep l101.exe $file | head -1 | grep g16`" ]; then
 version=g16
 echo This output is from G16
fi

if [ -z $version ]; then
    echo -n "something is wrong, which version of Gaussian are you using? g03 or g09 >"
    read version
    if [ "$version" != "g03" ] && [ "$version" != "g09" ]; then
     echo try again, must be g03 or g09
     exit
    fi
fi

if [ "$build" == "true" ]; then

#set up override directories
if [ -n "$template_location_input" ]; then
 tmp_file_name=$template_input
 template_input="$template_location_input/$template_input"
 echo warning, using override location for template input file
#set up default type file locations
elif [ -n $template_location ]; then
 tmp_file_name=$template_input
 template_input="$template_location/$template_input"
fi

#set up override directories
if [ -n "$template_location_basis" ]; then
 tmp_file_name=$template_basis
 template_basis="$template_location_basis/$template_basis"
 echo warning, using override location for template basis file
#set up default type file locations
elif [ -n $template_location ]; then
 tmp_file_name=$template_basis
 template_basis="$template_location/$template_basis"
fi

 if [ ! -f $template_input ]; then

    inputfile=1.inp
    restofroute="opt freq gfinput scf=(xqc,maxcon=128,maxcyc=128)"
    if [ ! -f $inputfile ]; then
     echo "template input and 1.inp do not exist, exiting..."
     exit
    fi

    echo -n "no template input exists; use $inputfile? (y/n) > "
    read response
    if [ "$response" = "y" ]; then
     head_inputfile=head.inp
     tail_inputfile=tail.inp
     tmp_inputfile=new.inp
     if [ -f $tmp_inputfile ]; then
      rm -i $tmp_inputfile
     fi
     sed -e 's/^\*\*\*\*$/ \*\*\*\*/g' -e 's/^[[:space:]]*$//g' $inputfile > $tmp_inputfile

     j=1
     while [ `awk '{ print NF }' FS= $tmp_inputfile|tail -1` -eq 0 ] && [ `awk '{ print NF }' FS= $tmp_inputfile|tail -2|head -1` -eq 0 ];
     do
      sed -i '$d' $tmp_inputfile
      j=$(($j+1))
     done

     first_blank=`grep -n '^[[:space:]]*$' $tmp_inputfile | head -1 | sed 's/://g'`

     #echo getting genecp
     genecp="`grep -i genecp $inputfile |awk '{print $1}'`"
     #echo getting gen1
     gen1="`grep -i gen $inputfile |grep -v genecp |awk '{print $1}'`"
     if [ $debug = 1 ]; then
      echo \$genecp is $genecp
      echo \$gen1 is $gen1
     fi

     if [ -n "$genecp" ]; then
      last_needed_blank=$((`grep -n '^[[:space:]]*$' $tmp_inputfile | tail -3 | head -1 | sed 's/://g'` + 1 ))
      awk 'NR=='"$last_needed_blank"',NR==last' $tmp_inputfile > $tail_inputfile
      template_basis=$tail_inputfile
     elif [ -n "$gen1" ]; then
      last_needed_blank=$((`grep -n '^[[:space:]]*$' $tmp_inputfile | tail -2 | head -1 | sed 's/://g'` + 1 ))
      awk 'NR=='"$last_needed_blank"',NR==last' $tmp_inputfile > $tail_inputfile
      template_basis=$tail_inputfile
#     else # no gen or genecp
     fi
     head -$first_blank $tmp_inputfile > $head_inputfile
     template_input=$head_inputfile
# clean up the route line to get rid of everything after opt
#     sed -i -e 's%opt.*$%opt freq gfinput scf=(xqc,maxcon=128,maxcyc=128)%ig' $template_input
     sed -i -e 's%opt.*$%'"$restofroute"'%ig' $template_input
    else
     echo "need a \$template_input file (same as the one from the car script)"
     echo "if you need it, make sure to also supply a \$template_basis"
     exit
    fi
 fi

 if [ -f $template_basis ]; then
  echo using a $template_basis file for basis set
 else
  echo not using a \$template_basis file
 fi

 if [ -d $irc_pos ] && [ -d $irc_neg ]; then
  echo $irc_pos and $irc_neg irc directories already exist--**removing them**
  rm -rf $irc_pos
  rm -rf $irc_neg
  mkdir $irc_pos
  mkdir $irc_neg
 else
  mkdir $irc_pos
  mkdir $irc_neg
 fi
#head of input file
 cat $template_input >> $irc_pos/1.inp
 cat $template_input >> $irc_neg/1.inp

#title
 printf "the positive pertubation structure with scale %s\n\n" $scale >> $irc_pos/1.inp
 printf "the negative pertubation structure with scale %s\n\n" -$scale >> $irc_neg/1.inp

#charge, mult
 top=`grep "Leave Link  103" $file -n |head -1 | awk '{print $1}' | sed 's%:%%g'`
 if [ -n "`head -n $top $file |awk -F'\n' '{ORS=" "} {print $0}'| sed 's/\(.*\)/\L\1/' | awk -F \-\- ' /oniom/ {for (i=1; i<=NF; i++) print $i;}' | grep "oniom" `" ]; then
  oniom=1
  echo this is an ONIOM job
  if [ ! -f "$oniom_data" ]; then
   echo "need \"$oniom_data\", which contains the layer data file to build inputs
for an oniom job; this file must contain only the ONIOM data at the end of each line
in the original input file; no other data can be in this file"
   exit
  else
   echo reading file for oniom data
   old_IFS=$IFS
   IFS=$'\n'
   oniomdata=($(cat $oniom_data))
   IFS=$old_IFS
   if [ $printlevel == 2 ]; then
    ndata=`wc -l $oniom_data | awk '{print $1}'`
    echo $ndata
    for (( i = 0 ; i < ${#oniomdata[*]} ; i++ ))
     do
      echo the oniom data for atom $(($i+1)) is ${oniomdata[i]}
     done
    fi
  fi
  chargemult=(`grep Charge $file | head -3 | awk '{print $3, $6}'`)
  echo ${chargemult[@]} >> $irc_pos/1.inp
  echo ${chargemult[@]} >> $irc_neg/1.inp
 else
  oniom=0
  if [ "`grep Charge $file | grep Multiplicity | head -1 | awk '{print $1}'`" != "Charge" ] && [ "`grep Charge $file | grep Multiplicity | head -1 | awk '{print $4}'`" != "Multiplicity" ]; then
   echo something is wrong with Charge and/or Multiplicity, exiting...
   exit
  fi
  grep Charge $file | grep Multiplicity | head -1 | awk '{print $3, $6}' >> $irc_pos/1.inp
  grep Charge $file | grep Multiplicity | head -1 | awk '{print $3, $6}' >> $irc_neg/1.inp
 fi

fi

# from extract-geom-input.sh
 natoms=$(expr `grep -i NAtoms $file | awk ' {print $2} ' | head -n 1`)
 nlines=$(expr `grep -i NAtoms $file | awk ' {print $2} ' | head -n 1` + 5)
 nlines=$(expr $nlines - 1)

if [ "$build" == "false" ]; then
 grep -A $nlines "Standard orientation:" $file |tail -n $natoms| awk ' {printf "%-6s%14s%15s%15s\n", $2,$4,$5,$6} '
elif [ "$build" == "true" ]; then
 echo building input files
fi

# get the data
stdorientation=`grep -c "Standard orientation:" $file`

if [ "$stdorientation" -eq "0" ];then
 inporientation=`grep -c "Input orientation:" $file`
  if [ "$inporientation" -eq "0" ];then
   orientation=Z-Matrix
  else
   orientation=Input
  fi
else
 orientation=Standard
fi

elements=(`grep -A $nlines "$orientation orientation:" $file |tail -n $natoms| awk ' {print $2} '`)
coords=(`grep -A $nlines "$orientation orientation:" $file |tail -n $natoms| awk ' {printf "%14s%15s%15s\n", $4,$5,$6} '`)

if [ $version == "g09" ] || [ $version == "g16" ]; then
 pertubatoms=(`awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom  AN      X      Y      Z/,/4                      5                      6/'|egrep -v "Atom  AN      X      Y      Z|4                      5                      6"| awk '{print $1}'`)
 if [ "$tosp" == "true" ]; then # use the pertubations of the third imag freq
  echo using tosp
  pertub=(`awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom  AN      X      Y      Z/,/4                      5                      6/'|egrep -v "Atom  AN      X      Y      Z|4                      5                      6"| awk '{print $9, $10, $11}'`)
 elif [ "$sosp" == "true" ]; then # use the pertubations of the second imag freq
  echo using sosp
  pertub=(`awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom  AN      X      Y      Z/,/4                      5                      6/'|egrep -v "Atom  AN      X      Y      Z|4                      5                      6"| awk '{print $6, $7, $8}'`)
 else # use the pertubations of the first imag freq
  echo using fosp
  pertub=(`awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom  AN      X      Y      Z/,/4                      5                      6/'|egrep -v "Atom  AN      X      Y      Z|4                      5                      6"| awk '{print $3, $4, $5}'`)
 fi
elif [ $version == "g09" ] || [ $version == "g16" ]; then
 pertubatoms=(`awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom  AN      X      Y      Z/,/4                      5                      6/'|egrep -v "Atom  AN      X      Y      Z|4                      5                      6"| awk '{print $1}'`)
 if [ "$tosp" == "true" ]; then # use the pertubations of the third imag freq
  echo using tosp
  pertub=(`awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom  AN      X      Y      Z/,/4                      5                      6/'|egrep -v "Atom  AN      X      Y      Z|4                      5                      6"| awk '{print $9, $10, $11}'`)
 elif [ "$sosp" == "true" ]; then # use the pertubations of the second imag freq
  echo using sosp
  pertub=(`awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom  AN      X      Y      Z/,/4                      5                      6/'|egrep -v "Atom  AN      X      Y      Z|4                      5                      6"| awk '{print $6, $7, $8}'`)
 else # use the pertubations of the first imag freq
  echo using fosp
  pertub=(`awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom  AN      X      Y      Z/,/4                      5                      6/'|egrep -v "Atom  AN      X      Y      Z|4                      5                      6"| awk '{print $3, $4, $5}'`)
 fi
elif [ $version == "g03" ]; then
 pertubatoms=(`awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom /,/4                      5                      6/'|egrep -v "Atom |4                      5                      6"| awk '{print $1}'`)
 pertub=(`awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom /,/4                      5                      6/'|egrep -v "Atom |4                      5                      6"| awk '{print $3, $4, $5}'`)
fi

if [ $printlevel == 1 ]; then
awk '/and normal coordinates:/,/4                      5                      6/ {print}' $file | awk '/Atom  AN      X      Y      Z/,/4                      5                      6/'|egrep -v "Atom  AN      X      Y      Z|4                      5                      6"| awk '{print $3, $4, $5}'
fi

#route=`route.sh $file`

if [ $debug == 1 ]; then
echo "grep -A $nlines \"$orientation orientation:\" $file |tail -n $natoms| awk ' {print $2} '"
k=0
j=0
 for (( i = 1 ; i < $(($natoms+1)) ; i++ ))
 do
  if [ $i == "${pertubatoms[$j]}" ]; then
   echo $i, ${pertubatoms[$j]}, $k, $j, ${elements[$j]}, ${coords[j]}, ${coords[j+1]}, ${coords[j+2]}
   k=$(($k+2))
   j=$(($j+1))
  else
   echo $i, ${pertubatoms[$j]}, $k, $j, ${elements[$j]}, ${coords[j]}, ${coords[j+1]}, ${coords[j+2]}
  fi
 done
fi

if [ "$build" == "false" ]; then
printf "\nthe positive pertubation structure with scale %s\n" $scale
fi
j=0
k=0
l=0
 for (( i = 1 ; i < $(($natoms+1)) ; i++ ))
 do
  if [ $debug == 2 ]; then
   echo $i, ${pertubatoms[$j]}, $k, $j
  fi
  if [ $i == "${pertubatoms[$j]}" ]; then
   newcoords=(${newcoords[@]} `echo "(${coords[i-1+l]} + ${pertub[j+k]}  *  $scale) "| bc -l`)
   newcoords=(${newcoords[@]} `echo "(${coords[i+0+l]} + ${pertub[j+k+1]}*  $scale) "| bc -l`)
   newcoords=(${newcoords[@]} `echo "(${coords[i+1+l]} + ${pertub[j+k+2]}*  $scale) "| bc -l`)
   frz=(${frz[@]} " 0")
   if [ $printlevel == 2 ]; then
   printf "%3d %3d %+9.6f %+4.2f %+9.6f %+9.6f %+4.2f %+9.6f %+9.6f %+4.2f %+9.6f\n" \
   $i ${frz[i-1]} \
   ${coords[i-1+k]} ${pertub[j+k]}   ${newcoords[i-1+k]} \
   ${coords[i+0+k]} ${pertub[j+k+1]} ${newcoords[i+0+k]} \
   ${coords[i+1+k]} ${pertub[j+k+2]} ${newcoords[i+1+k]} 
   fi
   k=$(($k+2))
   j=$(($j+1))

  else
   newcoords=(${newcoords[@]} ${coords[i-1+l]} ${coords[i+0+l]} ${coords[i+1+l]} )
   frz=(${frz[@]} "-1")
   if [ $printlevel == 2 ]; then
   printf "%3d %3d %+9.6f                 %+9.6f                 %+9.6f\n" \
   $i ${frz[i-1]} ${coords[i-1+k]} ${coords[i+0+k]} ${coords[i+1+k]}
   fi
   
  fi
   l=$(($l+2))
 done

k=0
if [ "$build" == "false" ]; then
 for (( i = 0 ; i < $natoms ; i++ ))
 do
  printf "%-3s%2s%+15.6f%+15.6f%+15.6f\n" ${elements[i]} ${frz[i]} ${newcoords[i+k]} ${newcoords[i+k+1]} ${newcoords[i+k+2]}
  k=$(($k+2))
 done

elif [ "$build" == "true" ]; then
 if [ $version == "g09" ] || [ $version == "g16" ]; then
  if [ $oniom == 1 ]; then
   for (( i = 0 ; i < $natoms ; i++ ))
   do
    printf "%-5s%4s%+15.6f%+15.6f%+15.6f %s\n" ${elements[i]} ${frz[i]} ${newcoords[i+k]} ${newcoords[i+k+1]} ${newcoords[i+k+2]} "${oniomdata[i]}" >> $irc_pos/1.inp
    k=$(($k+2))
   done

  else
   for (( i = 0 ; i < $natoms ; i++ ))
   do
    printf "%-5s%4s%+15.6f%+15.6f%+15.6f\n" ${elements[i]} ${frz[i]} ${newcoords[i+k]} ${newcoords[i+k+1]} ${newcoords[i+k+2]} >> $irc_pos/1.inp
    k=$(($k+2))
   done
  fi

 else

  for (( i = 0 ; i < $natoms ; i++ ))
   do
    printf "%-5s%+15.6f%+15.6f%+15.6f\n" ${elements[i]} ${newcoords[i+k]} ${newcoords[i+k+1]} ${newcoords[i+k+2]} >> $irc_pos/1.inp
    k=$(($k+2))
   done
 fi
fi

#empty the newcoords array
newcoords=()

if [ "$build" == "false" ]; then
printf "\nthe negative pertubation structure with scale %s\n" -$scale
fi
j=0
k=0
l=0
 for (( i = 1 ; i < $(($natoms+1)) ; i++ ))
 do
  if [ $debug == 2 ]; then
   echo $i, ${pertubatoms[$j]}, $k, $j
  fi
  if [ $i == "${pertubatoms[$j]}" ]; then
   newcoords=(${newcoords[@]} `echo "(${coords[i-1+l]} + ${pertub[j+k]}  * -$scale) "| bc -l`)
   newcoords=(${newcoords[@]} `echo "(${coords[i+0+l]} + ${pertub[j+k+1]}* -$scale) "| bc -l`)
   newcoords=(${newcoords[@]} `echo "(${coords[i+1+l]} + ${pertub[j+k+2]}* -$scale) "| bc -l`)
#   frz=(${frz[@]} " 0")
   if [ $printlevel == 2 ]; then
   printf "%3d %3d %+9.6f %+4.2f %+9.6f %+9.6f %+4.2f %+9.6f %+9.6f %+4.2f %+9.6f\n" \
   $i ${frz[i-1]} \
   ${coords[i-1+k]} ${pertub[j+k]}   ${newcoords[i-1+k]} \
   ${coords[i+0+k]} ${pertub[j+k+1]} ${newcoords[i+0+k]} \
   ${coords[i+1+k]} ${pertub[j+k+2]} ${newcoords[i+1+k]} 
   fi
   k=$(($k+2))
   j=$(($j+1))

  else
   newcoords=(${newcoords[@]} ${coords[i-1+l]} ${coords[i+0+l]} ${coords[i+1+l]} )
#   frz=(${frz[@]} "-1")
   if [ $printlevel == 2 ]; then
   printf "%3d %3d %+9.6f                 %+9.6f                 %+9.6f\n" \
   $i ${frz[i-1]} ${coords[i-1+k]} ${coords[i+0+k]} ${coords[i+1+k]}
   fi
   
  fi
   l=$(($l+2))
 done

k=0
if [ "$build" == "false" ]; then
 for (( i = 0 ; i < $natoms ; i++ ))
 do
  printf "%-3s%2s%+15.6f%+15.6f%+15.6f\n" ${elements[i]} ${frz[i]} ${newcoords[i+k]} ${newcoords[i+k+1]} ${newcoords[i+k+2]}
  k=$(($k+2))
 done

elif [ "$build" == "true" ]; then
 if [ $version == "g09" ] || [ $version == "g16" ]; then
  if [ $oniom == 1 ]; then
   for (( i = 0 ; i < $natoms ; i++ ))
   do
    printf "%-5s%4s%+15.6f%+15.6f%+15.6f %s\n" ${elements[i]} ${frz[i]} ${newcoords[i+k]} ${newcoords[i+k+1]} ${newcoords[i+k+2]} "${oniomdata[i]}" >> $irc_neg/1.inp
    k=$(($k+2))
   done

  else
   for (( i = 0 ; i < $natoms ; i++ ))
   do
    printf "%-5s%4s%+15.6f%+15.6f%+15.6f\n" ${elements[i]} ${frz[i]} ${newcoords[i+k]} ${newcoords[i+k+1]} ${newcoords[i+k+2]} >> $irc_neg/1.inp
    k=$(($k+2))
   done
  fi

 else

  for (( i = 0 ; i < $natoms ; i++ ))
   do
    printf "%-5s%+15.6f%+15.6f%+15.6f\n" ${elements[i]} ${newcoords[i+k]} ${newcoords[i+k+1]} ${newcoords[i+k+2]} >> $irc_neg/1.inp
    k=$(($k+2))
   done
 fi
fi


if [ "$build" == "true" ]; then

 if [ -f "$irc_pos/1.inp" ]; then
  head_length=`grep -n '^[[:space:]]*$' $irc_pos/1.inp | head -1 |sed 's%:%%g'`
  if [ -n "$head_length" ]; then
   route_line_number=`head -$head_length $irc_pos/1.inp | grep -n "#" | head -1| awk '{print $1}' | cut -f1 -d:`
   if [ -n "$route_line_number" ]; then
    after=$(( $head_length - $route_line_number -1 ))
    if [ $after -lt 0 ]; then
     echo are you sure that $irc_pos/1.inp is an input file?
     exit
    fi
    is_opt="`head -$head_length $irc_pos/1.inp | grep -i opt`"
    if [ -z "$is_opt" ]; then
     echo "you need to check your route line, it does not contain an \"opt\" keyword"
    fi
   else
    echo could not determine the line number of the route line in $irc_pos/1.inp 
    exit
   fi
  else
   echo could not determine the line number of the first blank line in $irc_pos/1.inp 
   exit
  fi
 else
  echo $irc_pos/1.inp does not exist
  exit
 fi

 printf "\n" >> $irc_pos/1.inp
 printf "\n" >> $irc_neg/1.inp
 if [ -f $template_basis ]; then
  cat $template_basis >> $irc_pos/1.inp
  cat $template_basis >> $irc_neg/1.inp
 fi
fi

if [ $debug -ne 1 ]; then
 if [ -f "$tmp_inputfile" ]; then
  rm $tmp_inputfile
 fi
 if [ -f "$head_inputfile" ]; then
  rm $head_inputfile
 fi
 if [ -f "$tail_inputfile" ]; then
  rm $tail_inputfile
 fi
fi
