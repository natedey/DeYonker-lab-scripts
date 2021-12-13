#!/bin/bash
# CEW 09/24/2011
# usage:
#
# create-simpec-ir.sh
#

bindir=newbin
script_name=create-simspec-ir

if [ "$1" = "--help" ]; then
echo "This script extracts the IR frequencies and intensities from GXX output files
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
## flag:linewidth Linewidth(in_cm-1)
linewidth  1
#
## flag:units Input-Units_(cm-1)
units  cm-1
## flag:min  Minimum(cm-1)
min 400.0
#
## flag:max Maximum(cm-1)
max 4000.0
#
## flag:step Stepsize(cm-1)
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

if [ -f $SCRIPT_CONFIG_LOC/$script_name.config ]; then
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
    linewidth=1.
    units="cm-1"
    min=400.
    max=4000.
    step=1.
    plot=true
fi

echo working on $file

# if not a gaussian file, don't process it
isoutputfile=`head -1 $file | cut -f1 -d,`
if [ "$isoutputfile" != " Entering Gaussian System" ]; then
echo $file is not a Gaussian output file
exit
fi


echo "$lineshape $linewidth $units" > input-ir
echo "$min $max $step" >> input-ir
nfreq=$((`grep NAtoms $file |tail -1|awk '{print $4	}'`*3-6))
echo $nfreq >> input-ir
#awk -f ~/bin/extract-simspec-ir.awk $file >> input-ir
awk 'BEGIN{m=0; n=0; o=0}                                                          
/and normal coordinates/,/Thermochemistry/ {if ($1=="Frequencies"){
                                                                   freq[m,1]=$3
                                                                   freq[m,2]=$4
                                                                   freq[m,3]=$5
                                                                   m++}
                                           {if ($1=="IR"){
                                                                   inten[n,1]=$4
                                                                   inten[n,2]=$5
                                                                   inten[n,3]=$6
                                                                   n++}
                                                                   }
                                                                   }
END{{OFS=" "; ORS=" "}
for (x = 0; x <= m-1; x++) {print freq[x,1], inten[x,1],"\n",freq[x,2], inten[x,2],"\n",freq[x,3], inten[x,3],"\n"}
}' $file >> input-ir

/home/$USER/$bindir/simspec-ir input-ir
echo `pwd` > working.tmp
cat input-ir.out >> working.tmp
mv working.tmp input-ir.out
echo "nedit input-ir.out&"

if [ "$plot" == "true" ]; then
 echo "writing simspec-ir.dat and using plot-simspec-ir.sh to plot the spectrum"
 awk '/#_Fitted-Points/,/the_peaks_are/' input-ir.out |egrep -v "#|the_peaks_are"> simspec-ir.dat
 plot-simspec-ir.sh
fi
