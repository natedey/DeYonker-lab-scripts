#!/bin/bash
# CEW/RL 2/08/2012
# usage:
#
# create-simpec-nmr.sh
#

bindir=newbin
script_name=create-simspec-nmr

default_standard=30.9916
default_standard_element=H

if [ "$1" = "--help" ]; then
echo "This script extracts the isotropic shielding values from GXX output files
$script_name.sh arg1 (arg2) (arg3)
$script_name.sh single_filename element standard

where element is the atomic symbol for the element of interest
      and standard is the absolute isotropic shielding value (in ppm)
      to use for shifting the computed data to comapre with expt

if element is not given, then the config file will be read;
if the config file does not exist, then the default element is H

if standard is not given, then the config file will be read;
if the config file does not exist, then the default standard is for H


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
## flag:linewidth Linewidth(in_ppm)
linewidth    0.025  # safe for H
# linewidth   0.05
# linewidth   0.5    # safe for F
#
## flag:units Input-Units_(ppm)
units  ppm
#
## flag:element (Atomic symbol)
element H
#
## flag:standard (ppm)
standard 32.1570
#
## flag:min  Minimum(ppm)
min -1.0     # safe for H
#min -300.0     # safe for F (in beta-PGM)
#
## flag:max Maximum(ppm)
max 12.0     # safe for H
#max 0.0      # safe for F (in beta-PGM)
#
## flag:step Stepsize(ppm)
step 0.005     # safe for H
#step 0.25      # safe for F
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

if [ -n "$ALT_DIR" ]; then
 if [ ! -d "$ALT_DIR" ]; then
  echo "$ALT_DIR" does not exist
  exit
 fi
 echo using \$ALT_DIR:$ALT_DIR
 echo "  if desired, remove ALT_DIR env var with \"unset ALT_DIR\""
else
 ALT_DIR=./
fi

if [ -f $SCRIPT_CONFIG_LOC/$script_name.config ]; then
echo using non-default config file: $SCRIPT_CONFIG_LOC/$script_name.config
echo to stop using this non-default config file issue \"unset SCRIPT_CONFIG_LOC\"
    lineshape="`grep ^lineshape $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
    linewidth="`grep ^linewidth $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
        units="`grep ^units     $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
if [ -z "$2" ]; then
      element="`grep ^element   $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
fi
if [ -z "$3" ]; then
     standard="`grep ^standard  $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
fi
          min="`grep ^min       $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
          max="`grep ^max       $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
         step="`grep ^step      $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
         plot="`grep ^plot      $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
elif [ -f ~/$bindir/$script_name.config ]; then
echo using ~/$bindir/$script_name.config
    lineshape="`grep ^lineshape ~/$bindir/$script_name.config | awk '{print $2}'`"
    linewidth="`grep ^linewidth ~/$bindir/$script_name.config | awk '{print $2}'`"
        units="`grep ^units     ~/$bindir/$script_name.config | awk '{print $2}'`"
if [ -z "$2" ]; then
      element="`grep ^element   ~/$bindir/$script_name.config | awk '{print $2}'`"
fi
if [ -z "$3" ]; then
     standard="`grep ^standard  ~/$bindir/$script_name.config | awk '{print $2}'`"
fi
          min="`grep ^min       ~/$bindir/$script_name.config | awk '{print $2}'`"
          max="`grep ^max       ~/$bindir/$script_name.config | awk '{print $2}'`"
         step="`grep ^step      ~/$bindir/$script_name.config | awk '{print $2}'`"
         plot="`grep ^plot      ~/$bindir/$script_name.config | awk '{print $2}'`"
else
    lineshape=G
#    linewidth=0.5   # safe for F
    linewidth=0.025  # safe for H
 if [ -z "$2" ]; then
    element=$default_standard_element
    standard=$default_standard
    echo "**warning**, using default standard for $element"
 fi
    units=ppm
    min=-1.        # safe for H
    max=10.        # safe for H
    step=0.005     # safe for H
#    min=-300.        # safe for F
#    max=0.           # safe for F
#    step=0.05      # safe for F
    plot=true
fi

if  [ -n "$2" ]; then
 element="$2"
  echo "**warning** element overidden from command line"
  echo "**using user input for element**: $element"
fi
if [ -z "$element" ]; then
 element=$default_standard_element
fi

if  [ -n "$3" ]; then
 standard="$3"
 echo "**warning** standard overidden from command line"
fi
if [ -z "$standard" ]; then
 standard=$default_standard
fi

element_nmr="$element"_nmr

echo simulating spectrum for $element_nmr from $file

# if not a gaussian file, don't process it
isoutputfile=`head -1 $file | cut -f1 -d,`
if [ "$isoutputfile" != " Entering Gaussian System" ]; then
echo $file is not a Gaussian output file
exit
fi

npeaks="`grep Isotropic $file | grep "  $element " | awk '{print $3}' |grep -c Isotropic`"

if [ -z $npeaks ]; then
 echo there are no peaks, exiting...
 exit
fi
if [ $npeaks -eq 0 ]; then
 echo there are no peaks, exiting...
 exit
fi

echo "#_Lineshape(L(ORENTZIAN)/G(AUSSIAN)/P(seudoVoigt))) Linewidth(in_ppm)  Input_Units_(ppm)  Standard_(ppm)" > $ALT_DIR/$element_nmr
echo "$lineshape $linewidth $units $standard"                                  >> $ALT_DIR/$element_nmr
echo "# Minimum(ppm)   Maximum(ppm)   Stepsize(ppm)"                           >> $ALT_DIR/$element_nmr
echo "$min $max $step"                                                         >> $ALT_DIR/$element_nmr
echo "#_Number_of_calculated_peaks"                                            >> $ALT_DIR/$element_nmr
echo $npeaks                                                                   >> $ALT_DIR/$element_nmr
echo "#_Calculated_Input_Data_(ppm), abs_shielding, chemical_shift, intensity" >> $ALT_DIR/$element_nmr
grep Isotropic $file | grep "  $element " | awk '{print $5}'                   >> $ALT_DIR/$element_nmr
#/home/$USER/$bindir/simspec-nmr-onearg $ALT_DIR/$element_nmr
/home/$USER/$bindir/simspec-nmr $ALT_DIR/$element_nmr

echo "#`pwd`"                                       > $ALT_DIR/working.tmp
echo "#simulated spectrum for $element from $file ">> $ALT_DIR/working.tmp
cat $ALT_DIR/$element_nmr.out                      >> $ALT_DIR/working.tmp
mv $ALT_DIR/working.tmp $ALT_DIR/$element_nmr.out

echo "writing $ALT_DIR/$element_nmr.out
"

if [ "$plot" == "true" ]; then
 echo "writing $element_nmr.dat and using plot-simspec-nmr.sh to plot the spectrum"
 awk '/# Fitted Points/,NR==last' $ALT_DIR/$element_nmr.out |egrep -v "#|the_peaks_are"> $ALT_DIR/nmr-out
 plot-simspec-nmr.sh
fi

if [ "`grep "MP2" $file`" ]; then
  echo "***WARNING*** This may be an MP2 job! This script will parse both the RHF and MP2 peaks!
        You will get erroneous results!
        Please use create-simspec-nmr-mp2.sh
        "
fi
