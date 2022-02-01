#!/bin/bash
# CEW
# 09/16/2011

bindir=newbin
script_name=make-msi-series

if [ "$1" = "--help" ]; then
echo "This script
1) gets geometries from the output file
2) writes input-msi and msi files
3) transfers these files to a directory on leviathan, 141.225.147.5:\$location

$script_name
$script_name.sh filename step-number(s)/first/last/energies

several options can be set with a configuration file, $script_name.config
directory:  the leviathan directory to which to transfer files
fileprefix: the prefix for the log file and all of the coord and msi files
prelog:     any prelog to add to the Cerius2 log file
matchmodel: a model to use for matching
matchatoms: a set of atoms to use for matching
postlog:    any postlog to add to the Cerius2 log file

use $script_name.sh --config to see a reasonable default config file,
which, if to be read, must be written in the ~/$bindir/directory
if no config file exists, reasonable defaults are used

set and export \$SCRIPT_CONFIG_LOC variable to set a location for $script_name.config
using the absolute path is a better choice
e.g., to use a config file in the current pirectory, issue
 export SCRIPT_CONFIG_LOC=`pwd`
but this export would work
 export SCRIPT_CONFIG_LOC=.
"

if [ -n "$SCRIPT_CONFIG_LOC" ]; then
 echo "\$SCRIPT_CONFIG_LOC is currently set to:
$SCRIPT_CONFIG_LOC"
else
 echo "\$SCRIPT_CONFIG_LOC is not set"
fi

echo "
to use an alternate directory for the temporary files on penguin
use \$ALT_DIR env variable to set the location
e.g., export ALT_DIR=directory_name
"

if [ -n "$ALT_DIR" ]; then
 echo "\$ALT_DIR is currently set to:
$ALT_DIR"
else
 echo "\$ALT_DIR is not set"
fi

exit
elif [ "$1" = "--config" ]; then
echo "# here is the default config file for $script_name.sh
# if it exists, it should be named $script_name.config
#
## flag:fileprefix the prefix for the log file and all of the coord and msi files
fileprefix tmp
#
## flag:prelog any prelog to add to the Cerius2 log file
## to add reset defaults to the log file, keep prelog set, but do not give a file name
#prelog prelog.log
#
## flag:directory the leviathan directory to which to transfer files
directory tmp-transfer
#
## flag:matchmodel the model to use for matching, if not the first model
#matchmodel tmp-geom1
#
## flag:matchatoms the atoms to use for matching, a list of atom numbers separated by commas
matchatoms 1,2,3,4
#
## flag:postlog any postlog to add to the Cerius2 log file
# postlog postlog.log
#
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
 fileprefix="`grep ^fileprefix $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
     prelog="`grep ^prelog     $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $1}'`"
 prelogfile="`grep ^prelog     $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
    postlog="`grep ^postlog    $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
   location="`grep ^directory  $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
 matchmodel="`grep ^matchmodel $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
 matchatoms="`grep ^matchatoms $SCRIPT_CONFIG_LOC/$script_name.config | awk '{print $2}'`"
elif [ -f ~/$bindir/$script_name.config ]; then
 echo using ~/$bindir/$script_name.config config file
 fileprefix="`grep ^fileprefix ~/$bindir/$script_name.config | awk '{print $2}'`"
     prelog="`grep ^prelog     ~/$bindir/$script_name.config | awk '{print $1}'`"
 prelogfile="`grep ^prelog     ~/$bindir/$script_name.config | awk '{print $2}'`"
    postlog="`grep ^postlog    ~/$bindir/$script_name.config | awk '{print $2}'`"
   location="`grep ^directory  ~/$bindir/$script_name.config | awk '{print $2}'`"
 matchmodel="`grep ^matchmodel ~/$bindir/$script_name.config | awk '{print $2}'`"
 matchatoms="`grep ^matchatoms ~/$bindir/$script_name.config | awk '{print $2}'`"
else
 fileprefix="tmp"
 location=tmp-transfer
 matchatoms="1,2,3,4"
fi

remotedir=`ssh 141.225.147.5 "if [ -d "$location" ]; then
 echo yes
 else
 echo no
 fi"`

if [ "$remotedir" == "no" ]; then
  echo the $location directory does not exist on leviathan
  echo you need to add the $location directory on leviathan and/or change the directory in the config file
  exit
else
  echo using leviathan:$location directory to write msi files
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


if [ -z "$2" ]; then
 echo you need to enter at least one step number or energy
 exit
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
elif [ ! -w $ALT_DIR ]; then
 echo user $USER cannot write to $ALT_DIR
 echo change permissions for \$ALT_DIR
 exit
fi

#check to be sure we have some reasonable defaults
if [ -z "$fileprefix" ]; then
 fileprefix=tmp
 echo fileprefix is not set, using default value
fi
if [ -z "$location" ]; then
 location=tmp-transfer
 echo location is not set, using default value
fi
if [ -z "$matchatoms" ]; then
 matchatoms="1,2,3,4"
 echo matchatoms is not set, using default value
fi

arg=($@)
firststepidname=`echo ${arg[1]}|sed 's%\.%-%g'|sed 's%^-%%g'`

maxstep=`grep "Step number" $file | awk '{print $3}' | sort -n |tail -1`

#echo the number of command-line arguments is $#

if [ -f $ALT_DIR/$fileprefix-open.log ]; then
 rm $ALT_DIR/$fileprefix-open.log
fi

if [ -n "$prelog" ]; then
 if [ -f "$prelogfile" ]; then
  cat "$prelogfile" >> $ALT_DIR/$fileprefix-open.log
 else
     echo "$prelog" flag set, but $prelogfile does not exist, using reset defaults
     echo "_GUI/MODAL 1"                                                         >> $ALT_DIR/$fileprefix-open.log
     echo "_SYSTEM/REINIT_ALL"                                                   >> $ALT_DIR/$fileprefix-open.log
     echo "VIEW/OVERLAY"                                                         >> $ALT_DIR/$fileprefix-open.log
 fi
fi

i=1
while [ $i -lt $# ]; do
 stepid=${arg[$i]}
 stepidname=`echo ${arg[$i]}|sed 's%\.%-%g' |sed 's%^-%%g'`
 if [ "$stepid" == "first" ] \
    || [ "$stepid" == "last" ] \
    || [ "`echo $stepid | egrep ^[[:digit:]]+$`" != "" ] \
    && [ "$stepid" != "0" ]; then

   if [ "$stepid" == "first" ] || [ "$stepid" == "last" ]; then
#    extract-geom-step-output.sh $stepid $file
#    extract-geom-step-output.sh $stepid $file > $ALT_DIR/$fileprefix-geom-$stepidname
    extract-geom-output.sh $stepid $file > $ALT_DIR/$fileprefix-geom-$stepidname
   elif [ "`echo $stepid | egrep ^[[:digit:]]+$`" != "" ]; then
     if [ "$stepid" -le $maxstep ]; then
#      extract-geom-step-output.sh $stepid $file
#      extract-geom-step-output.sh $stepid $file > $ALT_DIR/$fileprefix-geom-$stepidname
      extract-geom-output.sh $stepid $file > $ALT_DIR/$fileprefix-geom-$stepidname
     else
      echo $stepid is not a valid step number, total number of steps is $maxstep
     fi
   fi
 elif [ "$stepid" == "0" ]; then
  echo $stepid is not a valid step number
 else
#  extract-geom-output.sh $stepid $file
  extract-geom-output.sh $stepid $file > $ALT_DIR/$fileprefix-geom-$stepidname
 fi

i=$((i+1))
done


  echo "FILES/LOAD  \"/home/$USER/$location/$fileprefix-geom-$firststepidname-out.msi\"" >> $ALT_DIR/$fileprefix-open.log
  echo "EDIT/CALCULATE_BONDING"                                                          >> $ALT_DIR/$fileprefix-open.log
#  echo "MODEL/SET_CURRENT Model($fileprefix-geom-$firststepidname-out)"                  >> $ALT_DIR/$fileprefix-open.log

if [ -n "$matchmodel" ]; then
  echo "MODEL/SET_CURRENT Model($matchmodel)"                                            >> $ALT_DIR/$fileprefix-open.log
  echo "SELECT/ATOM_PROPERTY  ID"                                                        >> $ALT_DIR/$fileprefix-open.log
  echo "SELECT/ATOM_PROPERTY_VALUE  \"$matchatoms\" "                                    >> $ALT_DIR/$fileprefix-open.log
  echo "SELECT/SELECT_OBJREF"                                                            >> $ALT_DIR/$fileprefix-open.log
  echo "MOVE/REFERENCE_MODEL  \"$matchmodel\""                                           >> $ALT_DIR/$fileprefix-open.log
  echo "MOVE/FIT_MODEL  \"$fileprefix-geom-$firststepidname-out\""                       >> $ALT_DIR/$fileprefix-open.log
  echo "MOVE/MATCH_MODELS"                                                               >> $ALT_DIR/$fileprefix-open.log
else
  echo "MOVE/REFERENCE_MODEL  \"$fileprefix-geom-$firststepidname-out\""                 >> $ALT_DIR/$fileprefix-open.log
  echo "SELECT/ATOM_PROPERTY  ID"                                                        >> $ALT_DIR/$fileprefix-open.log
  echo "SELECT/ATOM_PROPERTY_VALUE  \"$matchatoms\" "                                    >> $ALT_DIR/$fileprefix-open.log
  echo "SELECT/SELECT_OBJREF"                                                            >> $ALT_DIR/$fileprefix-open.log
fi

  if [ -f $ALT_DIR/$fileprefix-geom-$firststepidname ]; then
   msi $ALT_DIR/$fileprefix-geom-$firststepidname |grep Writing >& /dev/null
   if [ -f $ALT_DIR/$fileprefix-geom-$firststepidname-out.msi ]; then
    scp $ALT_DIR/$fileprefix-geom-$firststepidname $ALT_DIR/$fileprefix-geom-$firststepidname-out.msi $USER@141.225.147.5:$location
    rm $ALT_DIR/$fileprefix-geom-$firststepidname-out.msi
   fi
   rm $ALT_DIR/$fileprefix-geom-$firststepidname
  else
  echo **there will be issue because there is not a first msi file**
  fi
 
i=2
while [ $i -lt $# ]; do
 stepidname=`echo ${arg[$i]}|sed 's%\.%-%g' |sed 's%^-%%g'`
 if [ -f $ALT_DIR/$fileprefix-geom-$stepidname ]; then
  msi $ALT_DIR/$fileprefix-geom-$stepidname |grep Writing >& /dev/null
   if [ -f $ALT_DIR/$fileprefix-geom-$stepidname-out.msi ]; then
    scp $ALT_DIR/$fileprefix-geom-$stepidname $ALT_DIR/$fileprefix-geom-$stepidname-out.msi $USER@141.225.147.5:$location
    rm $ALT_DIR/$fileprefix-geom-$stepidname-out.msi
   fi 
  rm $ALT_DIR/$fileprefix-geom-$stepidname
  echo "FILES/LOAD  \"/home/$USER/$location/$fileprefix-geom-$stepidname-out.msi\""      >> $ALT_DIR/$fileprefix-open.log
  echo "EDIT/CALCULATE_BONDING"                                                          >> $ALT_DIR/$fileprefix-open.log
  echo "MOVE/FIT_MODEL  \"$fileprefix-geom-$stepidname-out\""                            >> $ALT_DIR/$fileprefix-open.log
  echo "MODEL/SET_VISIBLE"                                                               >> $ALT_DIR/$fileprefix-open.log
  echo "MOVE/MATCH_MODELS"                                                               >> $ALT_DIR/$fileprefix-open.log
 fi

i=$((i+1))
done

if [ -n "$postlog" ]; then
 if [ -f "$postlog" ]; then
  cat "$postlog" >> $ALT_DIR/$fileprefix-open.log
  else
  echo "$postlog" file does not exist, nothing added to log file
 fi
fi

 scp $ALT_DIR/$fileprefix-open.log $USER@141.225.147.5:$location
 rm $ALT_DIR/$fileprefix-open.log
