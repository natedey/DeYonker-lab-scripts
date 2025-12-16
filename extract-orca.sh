#!/bin/bash
# DAW 2025/12/5
# usage:
# extract-orca.sh [args]
# extracts computed energies/other info for orca files
# based on extract.sh for gaussian outputs

if [[ "$1" == *"-h"* ]]; then
echo "
This script extracts the following info from orca outputs:
1) output file path
2) E elect
3) Eo
4) E + thrm E
5) H
6) G
7) no. basis functions
8) no. imag freqs

Extracts from all orca.out files in dir and subdirs by default.
Other options:
extract.sh list [list file]  -to extract from orca.out in each dir listed in file
extract.sh [file(s)]  -to extract from specific file(s) (needs to be file name not directory)
"
exit
fi


if [ -z $1 ] || [[ "$1" == "list" ]]; then
  if [ -z $1 ]; then
    directories=( `find ./ -type d` )
  elif [[ "$1" == "list" ]]; then
    directories=( $(cat $2) )
  fi
  for i in "${directories[@]}"; do
    j=$(echo $i|sed 's%\.\/%%g')
    if test -s $i/orca.out; then
      anyoutput=1
      if grep -q "ORCA TERMINATED NORMALLY" $i/orca.out; then
        #needs extra check bc orca still terminates normally if runs out of opt cycles: is it a finished optimization or single point calculation or energy+freq calculation.
        if ( grep -q "Geometry Optimization Run" $i/orca.out && grep -q "THE OPTIMIZATION HAS CONVERGED" $i/orca.out ) || grep -q "Single Point Calculation" $i/orca.out || grep -q "Energy+Gradient Calculation" $i/orca.out; then
          scf=$(grep "Electronic energy                ..." $i/orca.out | awk '{print $4}')
          ZPE=$(grep "Zero point energy" $i/orca.out | awk '{print $5}')
          EZPE=$(echo $scf + $ZPE | bc)
          thmE=$(grep -m 1 "Total thermal energy" $i/orca.out | awk '{print $4}')
          H=$(grep "Total Enthalpy" $i/orca.out | awk '{print $4}')
          G=$(grep "Final Gibbs free energy" $i/orca.out | awk '{print $6}')
          nbasis=$(grep -a -m 1 "Number of basis functions" $i/orca.out | awk '{print "="$NF}')
          nimag=$(grep "imaginary mode" $i/orca.out | wc -l)
          echo "$(pwd)/$j $scf $EZPE $thmE $H $G $nbasis Nimag=$nimag"
        fi
      fi
    fi
  done
else
  for i in "$@"; do
    j=$(echo $i|sed 's%\.\/%%g')
    if test -s $i; then
      anyoutput=1
      if grep -q "ORCA TERMINATED NORMALLY" $i; then
        # check further: is it a finished optimization or single point calculation or energy+freq calculation.
        if ( grep -q "Geometry Optimization Run" $i && grep -q "THE OPTIMIZATION HAS CONVERGED" $i ) || grep -q "Single Point Calculation" $i || grep -q "Energy+Gradient Calculation" $i; then
          scf=$(grep "Electronic energy                ..." $i | awk '{print $4}')
          ZPE=$(grep "Zero point energy" $i | awk '{print $5}')
          EZPE=$(echo $scf + $ZPE | bc)
          thmE=$(grep -m 1 "Total thermal energy" $i | awk '{print $4}')
          H=$(grep "Total Enthalpy" $i | awk '{print $4}')
          G=$(grep "Final Gibbs free energy" $i | awk '{print $6}')
          nbasis=$(grep -a -m 1 "Number of basis functions" $i | awk '{print "="$NF}')
          nimag=$(grep "imaginary mode" $i | wc -l)
          echo "$(pwd)/$j $scf $EZPE $thmE $H $G $nbasis Nimag=$nimag"
        fi
      fi
    fi
  done
fi

if [ -z "$anyoutput" ]; then
 echo there were no output files!
fi

