#!/bin/bash
# CEW 07/30/2013
# usage:
#
# measure.sh (arg1)
#
## the script will print the distance between two sets of objects or the angle between three or four objects from GXX output files

script_name=measure

if [ "$1" = "--help" ]; then
echo "This script extracts the 'last' distance between two sets of objects
 or the angle between three or four objects from an GXX output file

for distance:
$script_name.sh filename comma_separated_atom_list1 comma_separated_atom_list2\; e.g.,
$script_name.sh 1.out 1,2 28

for angle:
$script_name.sh filename comma_separated_atom_list1 comma_separated_atom_list2 comma_separated_atom_list3\; e.g.,
$script_name.sh 1.out 1 28 29

for dihedral angle:
$script_name.sh filename comma_separated_atom_list1 comma_separated_atom_list2 comma_separated_atom_list3 comma_separated_atom_list4\; e.g.,
$script_name.sh 1.out 1,2 28 29 30

comma_separated_atom_list1 comma_separated_atom_list2 are the atoms to
calculate the angle
filename is the output file to be searched
 or
the text to use in a find command

$script_name.sh ' -name 1.out' 1,2 28 29 30
will use the all command line arguments for a find command in the current directory
and search for any files named 1.out and 1-fail\*-out
**note** the single quotes are required!
"
exit
fi

if [ -z "$2" ] || [ -z "$3" ]; then
 echo "missing a command line argument; need at least three"
 echo $script_name.sh filename comma_separated_atom_list1 comma_separated_atom_list2 comma_separated_atom_list3\; e.g.,
 echo $script_name.sh 1.out 1 2 3
 exit
fi

if [ -n "$1" ]; then
 echo expanding the command-line arguments to use in the find command
 echo "files=(\`find ./$1\`)"
 files=(`eval find ./$1`)
else
 echo you are missing a valid output file
 exit
fi

# echo here are the ${#files[*]} files: ${files[@]}

for (( i = 0 ; i < ${#files[*]} ; i++ ))
 do
# printf '\n%s\n' "the output file is $i ${files[i]}"
  # if not a gaussian file, don't process it
  isoutputfile=`head -1 ${files[i]} | cut -f1 -d,`
  if [ "$isoutputfile" == " Entering Gaussian System" ]; then

#instead of using a simple printf:
#      labelatoms="`printf '^%7s\n' ${cla1[$j]}`"
# we have to use this convoluted process to get a variable into the format part of the printf statement:
#      labelatom="`printf '%s\n' "printf '^%"$nspaces"s\n' ${cla1[$j]}"`"
#      labelatoms="`eval "$labelatom"`"
#  the formatting of the Standard orientation section is different
# Check to see if the output file is a G03 output file 
     if [ -n "`grep l101.exe ${files[i]} | head -1 | awk '{print $2}' |grep g03`" ]; then
      nspaces=5 # appears to be a G03 output file
     else # must be G09 output
      nspaces=7
     fi

   if [ `grep -c "Standard orientation" ${files[i]}` -lt 2 ]; then
    echo ${files[i]} does_not_have_enough_geometries
   else
    natoms="`grep -i NAtoms ${files[i]} | head -1 | awk ' {print $2} '`"
    nlines=$(($natoms+4))
    nsteps=`grep -c "Standard orientation" ${files[i]}`

    cla1=(`echo $2|sed 's%,% %g'`)
    cla2=(`echo $3|sed 's%,% %g'`)
    cla3=(`echo $4|sed 's%,% %g'`)

    ncla1=${#cla1[*]}
    ncla2=${#cla2[*]}
    ncla3=${#cla3[*]}

    for (( j = 0 ; j < ${#cla1[*]}; j++ ))
     do
      valid_atom="`echo ${cla1[$j]} | egrep ^[[:digit:]]+$`"
      if [ "$valid_atom" = "" ]; then
       echo this atom number is not valid: ${cla1[$j]}
       exit
      fi
      if [ ${cla1[$j]} -gt $natoms ]; then
       echo for ${files[i]}, ${cla1[$j]} is greater than the number of atoms, $natoms
       exit
      fi
     done

    for (( j = 0 ; j < ${#cla2[*]}; j++ ))
     do
      valid_atom="`echo ${cla2[$j]} | egrep ^[[:digit:]]+$`"
      if [ "$valid_atom" = "" ]; then
       echo this atom number is not valid: ${cla2[$j]}
       getout=1
      fi
      if [ ${cla2[$j]} -gt $natoms ]; then
       echo for ${files[i]}, ${cla2[$j]} is greater than the number of atoms, $natoms
       getout=1
      fi
     done

    for (( j = 0 ; j < ${#cla3[*]}; j++ ))
     do
      valid_atom="`echo ${cla3[$j]} | egrep ^[[:digit:]]+$`"
      if [ "$valid_atom" = "" ]; then
       echo this atom number is not valid: ${cla3[$j]}
       getout=1
      fi
      if [ ${cla3[$j]} -gt $natoms ]; then
       echo for ${files[i]}, ${cla3[$j]} is greater than the number of atoms, $natoms
       getout=1
      fi
     done

   if [ $(($getout)) -ne 1 ]; then
    for (( j = 0 ; j < ${#cla1[*]}; j++ ))
     do
#      labelatoms="`printf '^%7s\n' ${cla1[$j]}`"
      labelatom="`printf '%s\n' "printf '^%"$nspaces"s\n' ${cla1[$j]}"`"
      labelatoms="`eval "$labelatom"`"
      atoposx1=$atoposx1"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $4}' |tail -1`"
      atoposy1=$atoposy1"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $5}' |tail -1`"
      atoposz1=$atoposz1"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $6}' |tail -1`"
     done

    for (( j = 0 ; j < ${#cla2[*]}; j++ ))
     do
#      labelatoms="`printf '^%7s\n' ${cla2[$j]}`"
      labelatom="`printf '%s\n' "printf '^%"$nspaces"s\n' ${cla2[$j]}"`"
      labelatoms="`eval "$labelatom"`"
      atoposx2=$atoposx2"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $4}' |tail -1`"
      atoposy2=$atoposy2"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $5}' |tail -1`"
      atoposz2=$atoposz2"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $6}' |tail -1`"
     done

    for (( j = 0 ; j < ${#cla3[*]}; j++ ))
     do
#      labelatoms="`printf '^%7s\n' ${cla3[$j]}`"
      labelatom="`printf '%s\n' "printf '^%"$nspaces"s\n' ${cla3[$j]}"`"
      labelatoms="`eval "$labelatom"`"
      atoposx3=$atoposx3"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $4}' |tail -1`"
      atoposy3=$atoposy3"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $5}' |tail -1`"
      atoposz3=$atoposz3"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $6}' |tail -1`"
     done

      math="`echo "($atoposx1)/$ncla1"|sed 's%^(+%(%g'`"
      at1pos=(`echo "$math" |bc -l`)

      math="`echo "($atoposy1)/$ncla1"|sed 's%^(+%(%g'`"
      at1pos=( ${at1pos[@]} `echo "$math" |bc -l`)

      math="`echo "($atoposz1)/$ncla1"|sed 's%^(+%(%g'`"
      at1pos=( ${at1pos[@]} `echo "$math" |bc -l`)


      math="`echo "($atoposx2)/$ncla2"|sed 's%^(+%(%g'`"
      at2pos=(`echo "$math" |bc -l`)

      math="`echo "($atoposy2)/$ncla2"|sed 's%^(+%(%g'`"
      at2pos=( ${at2pos[@]} `echo "$math" |bc -l`)

      math="`echo "($atoposz2)/$ncla2"|sed 's%^(+%(%g'`"
      at2pos=( ${at2pos[@]} `echo "$math" |bc -l`)


if [ $# -eq 3 ]; then

      distance=`echo \
        "sqrt((${at1pos[0]} - ${at2pos[0]}) * (${at1pos[0]} - ${at2pos[0]}) +\
              (${at1pos[1]} - ${at2pos[1]}) * (${at1pos[1]} - ${at2pos[1]}) +\
              (${at1pos[2]} - ${at2pos[2]}) * (${at1pos[2]} - ${at2pos[2]}))"\
        | bc -l`

#echo ${at1pos[@]}
#echo ${at2pos[@]}

printf "%s %10.7f\n" ${files[i]}_$2_$3 $distance

elif [ $# -eq 4 ]; then

      math="`echo "($atoposx3)/$ncla3"|sed 's%^(+%(%g'`"
      at3pos=(`echo "$math" |bc -l`)

      math="`echo "($atoposy3)/$ncla3"|sed 's%^(+%(%g'`"
      at3pos=( ${at3pos[@]} `echo "$math" |bc -l`)

      math="`echo "($atoposz3)/$ncla3"|sed 's%^(+%(%g'`"
      at3pos=( ${at3pos[@]} `echo "$math" |bc -l`)

      distanceBA=`echo \
        "sqrt((${at1pos[0]} - ${at2pos[0]}) * (${at1pos[0]} - ${at2pos[0]}) +\
              (${at1pos[1]} - ${at2pos[1]}) * (${at1pos[1]} - ${at2pos[1]}) +\
              (${at1pos[2]} - ${at2pos[2]}) * (${at1pos[2]} - ${at2pos[2]}))"\
        | bc -l`

      distanceBC=`echo \
        "sqrt((${at3pos[0]} - ${at2pos[0]}) * (${at3pos[0]} - ${at2pos[0]}) +\
              (${at3pos[1]} - ${at2pos[1]}) * (${at3pos[1]} - ${at2pos[1]}) +\
              (${at3pos[2]} - ${at2pos[2]}) * (${at3pos[2]} - ${at2pos[2]}))"\
        | bc -l`

      w_x=`echo "(${at1pos[0]} - ${at2pos[0]})" |bc -l`
      w_y=`echo "(${at1pos[1]} - ${at2pos[1]})" |bc -l`
      w_z=`echo "(${at1pos[2]} - ${at2pos[2]})" |bc -l`
#echo $w_x, $w_y, $w_z

      v_x=`echo "(${at3pos[0]} - ${at2pos[0]})" |bc -l`
      v_y=`echo "(${at3pos[1]} - ${at2pos[1]})" |bc -l`
      v_z=`echo "(${at3pos[2]} - ${at2pos[2]})" |bc -l`
#echo $v_x, $v_y, $v_z

      w_v=`echo "($w_x*$v_x + $w_y*$v_y + $w_z*$v_z)" |bc -l`
      cos_angle=`echo "($w_v/($distanceBA * $distanceBC))" |bc -l`
#      arccos(x) = arctan(sqrt(1 - x*x )/ x)
      pi=`echo "4*a(1)" | bc -l`

# atan2 in bc gives the complementary angle
#      angle=`echo "a(sqrt(1 - $cos_angle*$cos_angle )/ $cos_angle) * 180/$pi" |bc -l`

#echo $w_v, $cos_angle, $angle

#awk "BEGIN{ pi = 4.0*atan2(1.0,1.0); degree = pi/180.0; print $* }"
###echo | awk "{print square($cos_angle)} function square(x) { return (x^2) }"
###echo | awk "{print num($cos_angle)} function num(x) { return ((1.-x^2)^0.5) }"
printf "%s %s %s %s " ${files[i]}_$2_$3_$4
echo | awk "{print acos($cos_angle)} function acos(x) { return atan2((1.-x^2)^0.5,x)*180/$pi }"


elif [ $# -eq 5 ]; then
    cla4=(`echo $5|sed 's%,% %g'`)
    ncla4=${#cla4[*]}

    for (( j = 0 ; j < ${#cla4[*]}; j++ ))
     do
      valid_atom="`echo ${cla4[$j]} | egrep ^[[:digit:]]+$`"
      if [ "$valid_atom" = "" ]; then
       echo this atom number is not valid: ${cla4[$j]}
       getout=1
      fi
      if [ ${cla4[$j]} -gt $natoms ]; then
       echo for ${files[i]}, ${cla4[$j]} is greater than the number of atoms, $natoms
       getout=1
      fi
     done

    for (( j = 0 ; j < ${#cla4[*]}; j++ ))
     do
#      labelatoms="`printf '^%7s\n' ${cla3[$j]}`"
      labelatom="`printf '%s\n' "printf '^%"$nspaces"s\n' ${cla4[$j]}"`"
      labelatoms="`eval "$labelatom"`"
      atoposx4=$atoposx4"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $4}' |tail -1`"
      atoposy4=$atoposy4"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $5}' |tail -1`"
      atoposz4=$atoposz4"+`grep -A$nlines "Standard orientation" ${files[i]} |egrep -v "Standard orientation|Center|Number|--" |grep "$labelatoms" |awk '{print $6}' |tail -1`"
     done

      math="`echo "($atoposx3)/$ncla3"|sed 's%^(+%(%g'`"
      at3pos=(`echo "$math" |bc -l`)

      math="`echo "($atoposy3)/$ncla3"|sed 's%^(+%(%g'`"
      at3pos=( ${at3pos[@]} `echo "$math" |bc -l`)

      math="`echo "($atoposz3)/$ncla3"|sed 's%^(+%(%g'`"
      at3pos=( ${at3pos[@]} `echo "$math" |bc -l`)

      math="`echo "($atoposx4)/$ncla4"|sed 's%^(+%(%g'`"
      at4pos=(`echo "$math" |bc -l`)

      math="`echo "($atoposy4)/$ncla4"|sed 's%^(+%(%g'`"
      at4pos=( ${at4pos[@]} `echo "$math" |bc -l`)

      math="`echo "($atoposz4)/$ncla4"|sed 's%^(+%(%g'`"
      at4pos=( ${at4pos[@]} `echo "$math" |bc -l`)

      distanceBA=`echo \
        "sqrt((${at1pos[0]} - ${at2pos[0]}) * (${at1pos[0]} - ${at2pos[0]}) +\
              (${at1pos[1]} - ${at2pos[1]}) * (${at1pos[1]} - ${at2pos[1]}) +\
              (${at1pos[2]} - ${at2pos[2]}) * (${at1pos[2]} - ${at2pos[2]}))"\
        | bc -l`

      distanceBC=`echo \
        "sqrt((${at3pos[0]} - ${at2pos[0]}) * (${at3pos[0]} - ${at2pos[0]}) +\
              (${at3pos[1]} - ${at2pos[1]}) * (${at3pos[1]} - ${at2pos[1]}) +\
              (${at3pos[2]} - ${at2pos[2]}) * (${at3pos[2]} - ${at2pos[2]}))"\
        | bc -l`

      distanceCD=`echo \
        "sqrt((${at4pos[0]} - ${at3pos[0]}) * (${at4pos[0]} - ${at3pos[0]}) +\
              (${at4pos[1]} - ${at3pos[1]}) * (${at4pos[1]} - ${at3pos[1]}) +\
              (${at4pos[2]} - ${at3pos[2]}) * (${at4pos[2]} - ${at3pos[2]}))"\
        | bc -l`

#normalized vectors
      w_x=`echo "(${at2pos[0]} - ${at1pos[0]})/$distanceBA" |bc -l`
      w_y=`echo "(${at2pos[1]} - ${at1pos[1]})/$distanceBA" |bc -l`
      w_z=`echo "(${at2pos[2]} - ${at1pos[2]})/$distanceBA" |bc -l`

      v_x=`echo "(${at3pos[0]} - ${at2pos[0]})/$distanceBC" |bc -l`
      v_y=`echo "(${at3pos[1]} - ${at2pos[1]})/$distanceBC" |bc -l`
      v_z=`echo "(${at3pos[2]} - ${at2pos[2]})/$distanceBC" |bc -l`

      u_x=`echo "(${at4pos[0]} - ${at3pos[0]})/$distanceCD" |bc -l`
      u_y=`echo "(${at4pos[1]} - ${at3pos[1]})/$distanceCD" |bc -l`
      u_z=`echo "(${at4pos[2]} - ${at3pos[2]})/$distanceCD" |bc -l`

#echo $w_x, $w_y, $w_z

# cross product: a×b= {y1 z2 - z1 y2; z1 x2 - x1 z2; x1 y2 - y1 x2}
#      n1_1=y1 z2 - z1 y2
      n1_x=`echo "$w_y * $v_z - $w_z * $v_y" |bc -l`
      n1_y=`echo "$w_z * $v_x - $w_x * $v_z" |bc -l`
      n1_z=`echo "$w_x * $v_y - $w_y * $v_x" |bc -l`
#echo $n1_x, $n1_y, $n1_z

      n2_x=`echo "$v_y * $u_z - $v_z * $u_y" |bc -l`
      n2_y=`echo "$v_z * $u_x - $v_x * $u_z" |bc -l`
      n2_z=`echo "$v_x * $u_y - $v_y * $u_x" |bc -l`
#echo $n2_x, $n2_y, $n2_z

      m1_x=`echo "$n1_y * $v_z - $n1_z * $v_y" |bc -l`
      m1_y=`echo "$n1_z * $v_x - $n1_x * $v_z" |bc -l`
      m1_z=`echo "$n1_x * $v_y - $n1_y * $v_x" |bc -l`
#echo $m1_x, $m1_y, $m1_z

# m2 should be zero
      m2_x=`echo "$n2_y * $v_z - $n2_z * $v_y" |bc -l`
      m2_y=`echo "$n2_z * $v_x - $n2_x * $v_z" |bc -l`
      m2_z=`echo "$n2_x * $v_y - $n2_y * $v_x" |bc -l`
#echo $m2_x, $m2_y, $m2_z

      x_x=`echo "$n1_x * $n2_x" |bc -l`
      x_y=`echo "$n1_y * $n2_y" |bc -l`
      x_z=`echo "$n1_z * $n2_z" |bc -l`
      x=`echo "$x_x + $x_y + $x_z" |bc -l`
#echo $x_x, $x_y, $x_z, $x

      y_x=`echo "$n2_x * $m1_x" |bc -l`
      y_y=`echo "$n2_y * $m1_y" |bc -l`
      y_z=`echo "$n2_z * $m1_z" |bc -l`
      y=`echo "$y_x + $y_y + $y_z" |bc -l`
#echo $y_x, $y_y, $y_z, $y

# echo | awk "{print angle($y,$x)} function angle(y,x) { return atan2(y,x)*180/$pi }"
      pi=`echo "4*a(1)" | bc -l`
printf "%s %s %s %s %s " ${files[i]}_$2_$3_$4_$5
echo | awk "{print atan2($y,$x)*180/$pi}"

else
      echo your command line argument appears to be incorrect, you need
      echo $script_name.sh filename comma_separated_atom_list1 comma_separated_atom_list2 comma_separated_atom_list3\; e.g.,
      echo $script_name.sh 1.out 1,2 28 29
fi


#     echo $#
#     if [ $(($#)) -lt 3 ]; then
#      printf "the-distances-between-atoms-$2-and-atoms-$3-AND-$3-and-atoms-$4-for %s: %10.7f %10.7f\n" ${files[i]} $distanceBA $distanceBC
#     else
#      echo your command line argument appears to be incorrect, you need
#      echo $script_name.sh filename comma_separated_atom_list1 comma_separated_atom_list2 comma_separated_atom_list3\; e.g.,
#      echo $script_name.sh 1.out 1,2 28 29
#     fi

   fi
   fi
  unset atoposx1
  unset atoposy1
  unset atoposz1
  unset atoposx2
  unset atoposy2
  unset atoposz2
  unset atoposx3
  unset atoposy3
  unset atoposz3
  unset atoposx4
  unset atoposy4
  unset atoposz4
  unset getout
  fi
 done

