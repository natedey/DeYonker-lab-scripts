#!/bin/bash
# CEW
# plots Energy and Force (and Eigenvalue) data from GXX minimum or saddle-point optimization output file

debug=0
bindir=newbin
script_name=plot

if [ "$1" == "--help" ]; then
echo "this script plots data with /public/apps/gnuplot/5.2.4/bin/gnuplot from an GXX optimization output file
plot.sh (arg1) (arg2) (arg3)
 where arg1 is a filename
  if no arg1 is given, then 1.out is processed
 where arg2 is an integer used for the number of first points to delete
  if you want to use arg2, you must also supply arg1
 where arg3 is an integer used for the number of last step to plot
  if you want to use arg3, you must also supply arg1 and arg2

$script_name.sh can use the $script_name.config file

run \"$script_name.sh --config\" to print a reasonable $script_name.config file

set and export \$SCRIPT_CONFIG_LOC variable to set a location for $script_name.config
e.g., to use a config file in the current pirectory, issue
export SCRIPT_CONFIG_LOC=.

to use an alternate directory for the temporary files, use \$alt_dir in the config file
or use \$ALT_DIR env variable to set the location (\$ALT_DIR takes precedence)
e.g., export ALT_DIR=directory_name
"
exit
elif [ "$1" = "--config" ]; then
echo "this script use the same format as the config file from $config_script_name.sh"
echo "# here is the default config file for $script_name.sh
# if it exists, it should be named ~/$bindir/$script_name.config
#
## flag:config_del_first
config_del_first  4
#
## flag:alt_dir
#alt_dir  /home/$USER/tmp
alt_dir ./
#
## flag:debug (true:false::1:0)
debug 0
#
## flag:debug (true:false::1:0)
print_all_redundants 0
#
## to comment out a flag, add a # before the flag
## to use the flag, remove the # before the flag
"
exit
fi

if [ ! -w `pwd` ] && [ -z $ALT_DIR ]; then
 echo user $USER cannot write to `pwd`
 echo consider using an \$ALT_DIR
 exit
fi

if [ -f $SCRIPT_CONFIG_LOC/$script_name.config ]; then
echo using non-default config file: $SCRIPT_CONFIG_LOC/$script_name.config
echo to stop using this non-default config file issue \"unset SCRIPT_CONFIG_LOC\"
    config_del_first="`grep ^config_del_first     $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
             alt_dir="`grep ^alt_dir              $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
               debug="`grep ^debug                $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
print_all_redundants="`grep ^print_all_redundants $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
elif [ -f ./$script_name.config ]; then
echo using non-default config file: ./$script_name.config
echo to stop using this non-default config file delete the file, \"rm $script_name.config\"
    config_del_first="`grep ^config_del_first     ./$script_name.config | awk '{print $2}'`"
             alt_dir="`grep ^alt_dir              ./$script_name.config | awk '{print $2}'`"
               debug="`grep ^debug                ./$script_name.config | awk '{print $2}'`"
print_all_redundants="`grep ^print_all_redundants ./$script_name.config | awk '{print $2}'`"
elif [ -f ~/$bindir/$script_name.config ]; then
echo using default ~/$bindir/$script_name.config
echo to use a non-default config file issue \"export SCRIPT_CONFIG_LOC=.\" in the current directory
echo and edit a $script_name.config file in the current directory
    config_del_first="`grep ^config_del_first     $bindir/$script_name.config | awk '{print $2}'`"
             alt_dir="`grep ^alt_dir              $bindir/$script_name.config | awk '{print $2}'`"
               debug="`grep ^debug                $bindir/$script_name.config | awk '{print $2}'`"
print_all_redundants="`grep ^print_all_redundants $bindir/$script_name.config | awk '{print $2}'`"
else
 echo "defaults have been used from the script, parameters have not been read from any config file"
    config_del_first=4
fi

if [ "$alt_dir" == "" ]; then
 alt_dir=./
fi

if [ -n "$ALT_DIR" ]; then
 alt_dir=$ALT_DIR
 echo using \$ALT_DIR:$ALT_DIR 
fi

if [ ! -d "$alt_dir" ]; then
 echo "$alt_dir" does not exist
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
 file=1.out
fi

echo working on file $file

label=`pwd | sed 's%/home/'"$USER"/'%%g'`

# if not a gaussian file, don't process it
if [ ! -f "$file" ]; then
 echo "$file" file does not exist
 exit
fi

isoutputfile=`head -1 "$file" | cut -f1 -d,`
if [ "$isoutputfile" != " Entering Gaussian System" ]; then
 echo "$file" is not a Gaussian output file
 exit
fi

top=`grep "Leave Link  103" $file -n |head -1 | awk '{print $1}' | sed 's%:%%g'`
deriv="`head -$top $file| grep -c 'calc D2E/DXDY'`"
freq=`head -n $top $file |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \-\-\- ' /#/ {for (i=1; i<=NF; i++) print $i;} ' | sed 's/  //g' | grep "#" | grep freq`
ts=`head -n $top $file |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \-\-\- ' /#/ {for (i=1; i<=NF; i++) print $i;} ' | sed 's/  //g' | grep "#" | egrep "ts|qst"`

isnormaloutputfile=`tail -n 1 $file |awk '{print $1, $2}'`
if [ "$isnormaloutputfile" != "Normal termination" ]; then
 echo $file failed to terminate properly
else
normal=1
fi

if [ "$debug" == "1" ]; then
 if [ "$deriv" -gt "0" ]; then
  echo warning possibly numerical second derivatives!
  echo the number of second derivatives is "$deriv"
 fi
 if [ -n "$freq" ]; then
  echo this is also a freqency job
 fi
 if [ -n "$ts" ]; then
  echo this is also a TS job
 fi
fi

isoniomoutputfile=`grep "ONIOM: extrapolated" "$file" | head -1`
istddft=`grep "Total Energy" "$file" | head -1`
if [ -n "$isoniomoutputfile" ]; then
 echo "$file" is a ONIOM Gaussian output file
 energy=(`grep "ONIOM: extrapolated" $file |awk '{print $5}'`)
elif [ -n "$istddft" ]; then
 energy=(`grep "Total Energy"        $file |awk '{print $5}'`)
else
 energy=(`grep "SCF Done"        $file |awk '{print $5}'`)
fi

if [ -n "$freq" ] && [ -n "$normal" ]; then
 totalsteps=`grep "Step number" $file |tail -2 |head -1 | awk '{print $3}'`
else
 totalsteps=`grep "Step number" $file |tail -1 | awk '{print $3}'`
fi
if [ "$debug" == "1" ]; then
 echo total number of steps is $totalsteps
fi

number=(`grep "Step number"     $file |awk '{print $3}'`)
rmsforce=(`grep "RMS     Force" $file |awk '{print $3}'`)
maxforce=(`grep "Maximum Force" $file |awk '{print $3}'`)
if [ -n "$ts" ]; then
 if [ -f eigenvalue.dat ]; then
  rm eigenvalue.dat
 fi
 eigenvalue=(`awk '/Step number /,/Eigenvalues --- /' $file | grep "Eigenvalues --- " | awk '{ print $3 }'`)
fi


if [ -f $alt_dir/energy.dat ]; then
 rm $alt_dir/energy.dat
 rm $alt_dir/force.dat
fi

if [ -n "$2" ]; then
 delfirst=$2
  test $delfirst -eq 0 2>/dev/null
  if [ $? -eq 2 ]; then
   echo the second command-line argument, $delfirst, is not an integer, exiting...
   exit
  fi
 echo deleting the first $delfirst points
else
# delfirst=4
 delfirst=$config_del_first
fi

if [ $totalsteps -le $(($delfirst+1)) ]; then
echo the number of available steps is less than the number you requested to delete
exit
fi

if [ -n "$3" ]; then
 lastpoint=$3
  test $lastpoint -eq 0 2>/dev/null
  if [ $? -eq 2 ]; then
   echo the third command-line argument, $lastpoint, is not an integer, exiting...
   exit
  fi
 if [ $(($3 - $2)) -lt 2 ]; then
  if [ $(($3 - $2)) -eq 1 ]; then
   echo there is no point in plotting only one data point
   exit
  elif [ $(($3 - $2)) -lt 1 ]; then
   echo rethink your math\! you cannot have zero or a negative number of data points
   exit
  fi
 fi
 if [ $(($3 - $2)) -gt $((${#number[*]}-1)) ]; then
  echo the number of points requested is greater than the number of data points available
  exit
 fi
 echo the number of data points will be $(($3 - $2))
 echo the last data point will be $lastpoint
else
 if [ -n "$freq" ]; then
  lastpoint=$((${#number[*]}-1))
  echo the last data point will be $lastpoint
 else
  lastpoint=$((${#number[*]}))
  echo the last data point will be $lastpoint
 fi
fi

if [ $(($lastpoint)) -gt $(($totalsteps)) ]; then
 echo the number of points requested \($lastpoint\) is greater than the total number of data points available \($totalsteps\)
 exit
fi

if [ ${#number[*]} -lt $delfirst ]; then
 echo warning, the number of steps is less than $delfirst, exiting script
 exit
fi


#for i in ${number[@]}
 for (( i = $delfirst ; i < $lastpoint ; i++ ))
do
 printf "%s %s %s\n" ${number[$i]} ${energy[$i+$deriv]}   >> $alt_dir/energy.dat
 printf "%s %s %s\n" ${number[$i]} ${rmsforce[$i]} ${maxforce[$i]} >> $alt_dir/force.dat
done

echo "set term x11 title 'Energies   steps:$delfirst - $lastpoint   $label/$file'
set xlabel \"Step Number\"
set ylabel \"Energy (hartees)\"
set format x \"%.f\"
set format y \"%.6f\"
set mouse mouseformat \"mouse = %., %.6f\"
plot \"$alt_dir/energy.dat\" using 1:2 with linespoints title \"SCF Energy\" " > $alt_dir/gnu.energy.plt

echo "set term x11 title 'RMS Forces   steps:$delfirst - $lastpoint   $label/$file'
set xlabel \"Step Number\"
set format y \"%.6f\"
set ylabel \"Forces (hartees/bohr)\"
set style line 1 lt 1 lw 2
set style arrow 1 nohead ls 1
set arrow from $(($delfirst+1)),0.00030 to $(($lastpoint)),0.00030 as 1
plot \"$alt_dir/force.dat\" using 1:2 with linespoints title \"RMS Force\" "   > $alt_dir/gnu.rmsforce.plt

echo "set term x11 title 'RMS + MAX Forces   steps:$delfirst - $lastpoint   $label/$file'
set xlabel \"Step Number\"
set format y \"%.6f\"
set ylabel \"Forces (hartees/bohr)\"
set style line 1 lt 1 lw 2
set style line 2 lt 3 lw 2
set style arrow 1 nohead ls 1
set style arrow 2 nohead ls 2
set arrow from $(($delfirst+1)),0.00030 to $(($lastpoint)),0.00030 as 1
set arrow from $(($delfirst+1)),0.00045 to $(($lastpoint)),0.00045 as 2
plot \"$alt_dir/force.dat\" using 1:2 with linespoints title \"RMS Force\" , \
           \"$alt_dir/force.dat\" using 1:3 with linespoints lt 3 title \"MAX Force\" "   > $alt_dir/gnu.force.plt


echo plotting the forces, energies, and eigenvalues
/public/apps/gnuplot/5.2.4/bin/gnuplot -persist $alt_dir/gnu.force.plt
/public/apps/gnuplot/5.2.4/bin/gnuplot -persist $alt_dir/gnu.rmsforce.plt
/public/apps/gnuplot/5.2.4/bin/gnuplot -persist $alt_dir/gnu.energy.plt

echo "
click on the plot and press 'q' to close the plot
"

if [ -n "$ts" ]; then
 for (( i = $delfirst ; i < $lastpoint ; i++ ))
  do
   printf "%s %s %s\n" ${number[$i]} ${eigenvalue[$i]} >> $alt_dir/eigenvalue.dat
  done

 echo "set term x11 title 'Eigenvalues   steps:$delfirst - $lastpoint   $label/$file'
 set xlabel \"Step Number\"
 set format y \"%.6f\"
 set ylabel \"Eigenvalues\"
 set mouse mouseformat \"mouse = %, %.6f\"
 plot \"$alt_dir/eigenvalue.dat\" using 1:2 with linespoints title \"Eigenvalues\" "   > $alt_dir/gnu.eigenvalue.plt

 /public/apps/gnuplot/5.2.4/bin/gnuplot -persist $alt_dir/gnu.eigenvalue.plt

 if [ -z "`grep -$top "Gaussian 03" $file`" ]; then
  if [ -z "$print_all_redundants" ] || [ "$print_all_redundants" == "0" ]; then
   echo the bond making/breading modes that were/became important during the TS opt are:
   awk '/Eigenvectors required to have negative eigenvalues:/,/RFO step: / || /Angle between / || /QST in optimization variable space/' "$file" \
   | egrep -v "Eigenvectors|Eigenvalue|RFO step|Angle|   1               " \
   | sed -e 's%R%\nR%g' -e 's%A%\nA%g' -e 's%D%\nD%g' \
         -e 's%X%\nX%g' -e 's%Y%\nY%g' -e 's%Z%\nZ%g' \
         -e 's% %%g' \
   | grep -v "^[[:space:]]*$" \
   | grep R | sort | uniq
  elif [ "$print_all_redundants" == "1" ]; then
   echo the redundant internal coordinates that were/became important during the TS opt are:
   awk '/Eigenvectors required to have negative eigenvalues:/,/RFO step: / || /Angle between / || /QST in optimization variable space/' "$file" \
   | egrep -v "Eigenvectors|Eigenvalue|RFO step|Angle|   1               " \
   | sed -e 's%R%\nR%g' -e 's%A%\nA%g' -e 's%D%\nD%g' \
         -e 's%X%\nX%g' -e 's%Y%\nY%g' -e 's%Z%\nZ%g' \
         -e 's% %%g' \
   | grep -v "^[[:space:]]*$" \
   | egrep "R|A|D|X|Y|Z" | sort | uniq
  fi
   printf "\n%s\n" "Warning!!! frozen coordinate(s) is/are showing up during the TS opt:"
   awk '/Eigenvectors required to have negative eigenvalues:/,/RFO step: / || /Angle between / || /QST in optimization variable space/' "$file" \
   | egrep -v "Eigenvectors|Eigenvalue|RFO step|Angle|   1               " \
   | sed -e 's%R%\nR%g' -e 's%A%\nA%g' -e 's%D%\nD%g' \
         -e 's%X%\nX%g' -e 's%Y%\nY%g' -e 's%Z%\nZ%g' \
         -e 's% %%g' \
   | grep -v "^[[:space:]]*$" \
   | egrep "X|Y|Z" | sort | uniq
 fi

fi

if [ "$debug" != "1" ]; then
 rm $alt_dir/energy.dat $alt_dir/force.dat $alt_dir/gnu.energy.plt $alt_dir/gnu.force.plt $alt_dir/gnu.rmsforce.plt
 if [ -n "$ts" ]; then
  rm $alt_dir/gnu.eigenvalue.plt $alt_dir/eigenvalue.dat
 fi
fi

