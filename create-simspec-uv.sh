#!/bin/bash
# CEW 05/03/2013
# usage:
#
# create-simpec-uv.sh
#

bindir=newbin
script_name=create-simspec-uv

if [ "$1" = "--help" ]; then
echo "This script extracts the TDDFT transitions and intensities from GXX output files
$script_name.sh single_filename

run \"$script_name.sh --config\" to print a reasonable $script_name.config file

the default is ~/$bindir/$script_name.config

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
## flag:lineshape Lineshape(L(ORENTZIAN)/G(AUSSIAN)/P(seudoVoigt)))
lineshape  G
#
## flag:linewidth Linewidth(in_nm)
linewidth  10
#
## flag:units Input-Units_(nm/eV)
units  nm
#
## flag:min  Minimum(nm)
min 100.0
#
## flag:max Maximum(nm)
max 900.0
#
## flag:step Stepsize(nm)
step 1.0000
#
## flag:plot whether to plot with gnuplot (true/false)
plot true
#
## to comment out a flag, add a # before the flag
## to use the flag, remove the # before the flag
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

if [ -n "$SCRIPT_CONFIG_LOC" ]; then
 echo using \$SCRIPT_CONFIG_LOC:$SCRIPT_CONFIG_LOC
 if [ ! -f $SCRIPT_CONFIG_LOC/$script_name.config ]; then
  \$SCRIPT_CONFIG_LOC/$script_name.config does not exist
  exit
 fi
echo using non-default config file: $SCRIPT_CONFIG_LOC/$script_name.config
echo to stop using this non-default config file issue \"unset SCRIPT_CONFIG_LOC\"
    lineshape="`grep ^lineshape $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
    linewidth="`grep ^linewidth $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
        units="`grep ^units     $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
          min="`grep ^min       $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
          max="`grep ^max       $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
         step="`grep ^step      $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
         plot="`grep ^plot      $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
elif [ -f ~/$bindir/$script_name.config ]; then
echo using ~/$bindir/$script_name.config
    lineshape="`grep ^lineshape ~/$bindir/$script_name.config | awk '{print $2}'`"
    linewidth="`grep ^linewidth ~/$bindir/$script_name.config | awk '{print $2}'`"
        units="`grep ^units     ~/$bindir/$script_name.config | awk '{print $2}'`"
          min="`grep ^min       ~/$bindir/$script_name.config | awk '{print $2}'`"
          max="`grep ^max       ~/$bindir/$script_name.config | awk '{print $2}'`"
         step="`grep ^step      ~/$bindir/$script_name.config | awk '{print $2}'`"
         plot="`grep ^plot      ~/$bindir/$script_name.config | awk '{print $2}'`"
else
    lineshape=G
    linewidth=10.
    units=nm
    min=100.
    max=900.
    step=1.
    plot=true
fi

#function create-simspec() { command echo "G 10. nm" > input ; command echo "100. 900. 1." >> input ; command grep "\<nm\>" 1.out | awk '{print $9}' | grep -c f >> input ; command grep "Excited State " 1.out | awk '{print $7,$9}' | command sed 's/f=//g' >> input; ~/bin/simspec input; }

echo working on $file

if [ "$ALT_DIR" == "" ]; then
 ALT_DIR=./
fi

if [ -n "$ALT_DIR" ]; then
 echo using \$ALT_DIR:$ALT_DIR
 echo "  if desired, remove ALT_DIR env var with \"unset ALT_DIR\""
fi

if [ ! -d "$ALT_DIR" ]; then
 echo "$ALT_DIR" does not exist
 exit
fi

# if not a gaussian file, don't process it
isoutputfile=`head -1 $file | cut -f1 -d,`
if [ "$isoutputfile" != " Entering Gaussian System" ]; then
echo $file is not a Gaussian output file
exit
fi

# find out the line number to which to process with head
top=`grep -n "Leave Link    1" $file | head -1 | sed 's%:% %g' | awk '{print $1}'`

if [ -z $nstates ]; then
nstates="`head -n $top $file | sed 's/\(.*\)/\L\1/' |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \-\- ' /nstates/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /n  states/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /ns  tates/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /nst  ates/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /nsta  tes/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /nstat  es/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /nstate  s/ {for (i=1; i<=NF; i++) print $i;} \
' \
| sed 's/  //g' | grep nstates | sed 's/(/  /g' \
| awk -F \, ' /nstates/ {for (i=1; i<=NF; i++) print $i;}' \
| awk -F' ' ' /nstates/ {for (i=1; i<=NF; i++) print $i;}' |grep nstates | sed 's/)//g' | sed 's/nstates=//g' 
`"

fi
if [ -z $nstates ]; then
# keep checking for nstates, user could have used nstate instead
nstates="`head -n $top $file | sed 's/\(.*\)/\L\1/' |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \-\- ' /nstate/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /n  state/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /ns  tate/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /nst  ate/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /nsta  te/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /nstat  e/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /nstate  / {for (i=1; i<=NF; i++) print $i;} \
' \
| sed 's/  //g' | grep nstate | sed 's/(/  /g' \
| awk -F \, ' /nstate/ {for (i=1; i<=NF; i++) print $i;}' \
| awk -F' ' ' /nstate/ {for (i=1; i<=NF; i++) print $i;}' |grep nstate | sed 's/)//g' | sed 's/nstate=//g' 
`"

fi

fiftyfifty="`head -n $top $file | sed 's/\(.*\)/\L\1/' |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \-\- ' /nstates/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /5  0-50/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /50  -50/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /50-   50/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /50-5   0/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /50-50    / {for (i=1; i<=NF; i++) print $i;} \
' \
| sed 's/  //g' | grep 50-50 | sed 's/(/  /g' \
| awk -F \, ' /50-50/ {for (i=1; i<=NF; i++) print $i;}' \
| awk -F' ' ' /50-50/ {for (i=1; i<=NF; i++) print $i;}' |grep 50-50 | sed 's/)//g' | sed 's/50-50=//g' 
`"

if [ -n "$fiftyfifty" ]; then
 old_nstates=$nstates
 nstates=$((2*$nstates))
fi

# keep checking for nstates, user could have used add instead
if [ -z $nstates ]; then
addstates="`head -n $top $file | sed 's/\(.*\)/\L\1/' |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \-\- ' /nstates/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /a  dd/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /ad  d/ {for (i=1; i<=NF; i++) print $i;} \
                                                                             /add/ {for (i=1; i<=NF; i++) print $i;} \
' \
| sed 's/  //g' | grep add | sed 's/(/  /g' \
| awk -F \, ' /add/ {for (i=1; i<=NF; i++) print $i;}' \
| awk -F' ' ' /add/ {for (i=1; i<=NF; i++) print $i;}' |grep add | sed 's/)//g' | sed 's/add=//g' 
`"
 if [ -n "$addstates" ]; then
  echo "this job has used td(add=$addstates), you will need to check the input for simspec-uv"
  echo " and might need to run manually"
  echo "$lineshape $linewidth $units" > $ALT_DIR/input-uv
  echo "$min $max $step" >> $ALT_DIR/input-uv
  nstates=`grep "\<nm\>" $file | awk '{print $9}' | grep -c f`
  echo $nstates >> $ALT_DIR/input-uv
  grep "Excited State " $file |tail -n $nstates | awk '{print $7,$9}' | command sed 's/f=//g' >> $ALT_DIR/input-uv
  echo check the input-uv file and then run simspec-uv input-uv
 else
  echo there are not any computed states, $USER are you sure that this is a TD calc?
  exit
 fi
echo nstates is $nstates
fi

echo "$lineshape $linewidth $units" > $ALT_DIR/input-uv
echo "$min $max $step" >> $ALT_DIR/input-uv
#grep "\<nm\>" 1.out | awk '{print $9}' | grep -c f >> input

#echo nstates is $nstates
if [ -n "`route.sh $file |grep -i opt`" ] || [ -n "`route.sh $file |grep -i freq`" ]; then
 echo $nstates >> $ALT_DIR/input-uv
 grep "Excited State " $file |tail -n $nstates | awk '{print $7,$9}' | command sed 's/f=//g' >> $ALT_DIR/input-uv
elif [ $((`grep -c "Excited State " $file`)) -eq $nstates ]; then 
 echo $nstates >> $ALT_DIR/input-uv
 grep "Excited State " $file | awk '{print $7,$9}' | command sed 's/f=//g' >> $ALT_DIR/input-uv
elif [ $((`grep -c "Excited State " $file`)) -ne $nstates ]; then 
 echo $old_nstates >> $ALT_DIR/input-uv
 printf "\n"
 echo "**************************************************************************************************"
 echo "**something is wrong, number of \"Excited State\" is not equal to \$nstates, trying something...**"
 echo "**you better check the results\!**"
 echo "**************************************************************************************************"
 printf "\n"
 grep "Excited State " $file |tail -n $old_nstates | awk '{print $7,$9}' | command sed 's/f=//g' >> $ALT_DIR/input-uv
fi

/home/$USER/$bindir/simspec-uv $ALT_DIR/input-uv

echo `pwd` > $ALT_DIR/working.tmp
grep "Total Energy" $file |tail -1 | sed 's%, E(TD-HF/TD-KS)%%g' >> $ALT_DIR/working.tmp
cat $ALT_DIR/input-uv.out >> $ALT_DIR/working.tmp
mv $ALT_DIR/working.tmp $ALT_DIR/input-uv.out

echo "writing input-uv.out
"

if [ "$plot" == "true" ]; then
 echo "writing simspec-uv.dat and using plot-simspec-uv.sh to plot the spectrum"
 awk '/#_Fitted-Points/,/the_peaks_are/' $ALT_DIR/input-uv.out |egrep -v "#|the_peaks_are" > $ALT_DIR/simspec-uv.dat
 plot-simspec-uv.sh $ALT_DIR/input-uv.out
fi
