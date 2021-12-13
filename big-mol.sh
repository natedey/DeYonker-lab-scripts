#!/bin/bash
# CEW 08/17/2011
# usage:
#
# big-mol.sh (arg1)
#
##

bindir=newbin
molden_file=tmp-molden.mol 

if [ "$1" = "--help" ]; then
echo "This script extracts the data from an output GXX file to write a simple Molden format file
big-mol.sh (arg1) (arg2)
big-mol.sh output-filename tmp-molden-format-file

to use an alternate directory for the temporary files on penguin
use \$ALT_DIR env variable to set the location
e.g., export ALT_DIR=directory_name

you must have +rwx permissions on the \$ALT_DIR directory
"
exit
fi

if [ ! -w `pwd` ] && [ -z $ALT_DIR ]; then
 echo user $USER cannot write to `pwd`
 echo consider using an \$ALT_DIR, see \"big-mol.sh --help\"
 exit
fi

if [ -z "$1" ] && [ -f 1.out ]; then
 file=1.out
 echo using $molden_file to write molden file
elif [ -f "$1" ] && [ -z "$2" ]; then
 file="$1"
 echo using $molden_file to write molden file
elif [ -f "$1" ] && [ -n "$2" ]; then
 file="$1"
 molden_file="$2"
 echo using non-default $molden_file to write molden file
elif [ ! -f "$1" ] && [ -z "$2" ]; then
 file=1.out
 molden_file="$1"
 echo using $molden_file to write molden file
fi

if [ "$ALT_DIR" == "" ]; then
 ALT_DIR=./
elif [ -n "$ALT_DIR" ]; then
 echo using \$ALT_DIR:$ALT_DIR
fi

if [ ! -d "$ALT_DIR" ]; then
 echo "$ALT_DIR" does not exit
 echo "either unset ALT_DIR or create \$ALT_DIR with an export"
 exit
fi

 echo working on output file $file

 isoutputfile=`head -1 "$file" | cut -f1 -d,`
 if [ "$isoutputfile" != " Entering Gaussian System" ]; then
  echo "$file" is not a Gaussian output file
  echo are you sure that you meant to use "$file"?
  exit
 fi

if [ -f "$ALT_DIR/$molden_file" ]; then
 isoutputfile=`head -1 "$ALT_DIR/$molden_file" | cut -f1 -d,`
 if [ "$isoutputfile" == " Entering Gaussian System" ]; then
  echo "$ALT_DIR/$molden_file" is a Gaussian output file
  echo are you sure that you meant to use "$ALT_DIR/$molden_file" for \$"$molden_file"?
  echo "exiting..."
  exit
 fi
 echo deleting old \$molden_file $ALT_DIR/$molden_file
 rm $ALT_DIR/$molden_file
fi

isoniomoutputfile=`grep "ONIOM: extrapolated" "$file" | head -1`
istddft=`grep "Total Energy" "$file" | head -1`

if [ -n "$isoniomoutputfile" ]; then
 awk -f ~/$bindir/extract-molden-gXX-opt-oniom.awk $file > $ALT_DIR/$molden_file
elif [ -n "$istddft" ]; then
 awk -f ~/$bindir/extract-molden-gXX-tddft-opt.awk $file > $ALT_DIR/$molden_file
else
 if [ "`grep -c "Standard orientation:" $file`" -eq 0 ]; then
  echo no \"Standard orientation:\" section
  awk -f ~/$bindir/extract-molden-gXX-opt-nosym.awk $file > $ALT_DIR/$molden_file
 else
  awk -f ~/$bindir/extract-molden-gXX-opt.awk $file > $ALT_DIR/$molden_file
 fi
fi

molden -l -S $ALT_DIR/$molden_file >& /dev/null & 
