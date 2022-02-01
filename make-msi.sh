#!/bin/bash
# CEW 08/27/2011
# usage:
#
# make-msi.sh arg1 (arg2)
#
## the script will extract the coordinates, make msi input and msi output files
# and copy the files onto leviathan
#
# make-msi.sh arg1 (which is ${1})
# arg1 is the name of directory on leviathan to which to copy the files
#
# if a coords file already exists, then nothing will be extracted
#
# BE CAREFUL! scp will overwrite whatever files are on leviathan
#
# known issues: this script will not extract coordinates from a freq=restart
# output because the "Standard orientation" will not exist
#
# script dependencies:
# extract-coords.sh
# extract-energy.sh 
#
#test for one argument and no second argument
if [ -n "$2" ] && [ "$2" = "list" ]; then
directories=( `cat list` )
else
directories=( `find ./ -type d` )
fi


if [ "$1" = "--help" ]; then
echo "This script
1) extracts coordinates from G03 and G09 optimization output files
2) makes msi input
3) writes msi output files (with msi)
4) transfers the msi files to leviathan
        (needs a command line argument to transfer to the directory)

make-msi.sh arg1 (which is \$1)
arg1 is the name of directory on leviathan to which to copy the files

---------

If the script is run with \"list\" as arg2 then a \"list\" file is read
for which directories to process and an \"open.log\" file is written

make-msi.sh arg1 list (which is \$1 and \$2)
arg1 is the name of directory on leviathan to which to copy the files
list is arg2, a file containing a list directories to process

---------

If the script is run on a directory with an output file, then the
user can provide two command line arguments, one for the name of the
transfer directory and the second for the filename to which to transfer.

If there is an output file in the current directory, be aware that
any directories that exist will also get processed (but not transferred).

make-msi.sh arg1 arg2 (which is \$1 and \$2)
arg1 is the name of directory on leviathan to which to copy the files
arg2 is the filename of the file transferred to leviathan

---------

If a coords file already exists, then nothing will be extracted

BE CAREFUL! scp will overwrite whatever files are on leviathan

"
exit
fi

echo "use --help for the command line argument to get directions
"

#test for one argument and no second argument
if [ -n "$1" ] && [ -z "$2" ]; then
echo "transferring files to leviathan:$1
"
fi

#test for two arguments and "list" for second argument
if [ -n "$1" ] && [ "$2" = "list" ]; then
echo "transferring select files to leviathan:$1
"
 if [ -f open.log ]; then
  rm -i open.log
  if [ ! -f open.log ]; then
   echo "#open.log written by make-msi.sh for list in $1" > open.log
   echo "_GUI/MODAL 1" >> open.log
   echo "_SYSTEM/REINIT_ALL" >> open.log
   echo "VIEW/OVERLAY" >> open.log
  fi
 fi
fi

for i in "${directories[@]}"
do
#  if [ $i != "./" ]; then
# clean up the name of the directory to remove "/" from the name
     j=$(echo $i|sed 's%/%-%g')
     j=$(echo $j|sed 's%\.-%\.\/%g')
#    echo corrected directory name is $j

#test for "list" for second argument and write open.log
if [ "$2" = "list" ] && [ -f open.log ]; then
  echo "FILES/LOAD  \"/home/$USER/$1/$j-out.msi\"" >> open.log
fi

# make sure the coord file does not already exist
    if test -f $i/coords; then
     echo coords file already exists for $i/1.out
    else

# make sure the 1.out file exists
     if test -s $i/1.out; then

# check to see if the job completed normally
       if [ "`tail -1 $i/1.out |awk '{print $1, $2}'`" == "Normal termination" ]; then

       if test ! -f $i/coords; then
        echo processing: $i/1.out
       fi

# the part of the script checks for a KJOB run by looking back 6 lines from the last line for "*Kjob"
# need to see if that line contains nothing (because if statements will not work with an empty argument)
        if [ ! -n `tail -n 6 $i/1.out |head -n 1 |awk '{print $1}'` ]; then
          dSTR="dummy variable"
# or if that line contains something
        else
          STR=`tail -n 6 $i/1.out | head -n 1 |awk '{print $1}'`
        fi

# if the string is empty, give it a value: ${STR:-0} instead of just $STR
# sometimes, it is best to add quotes around a string: "STR" instead of STR because when the shell expands the variable it could have spaces or be empty
# if the string is not "*Kjob", do stuff
        if [ ${STR:-0} != "*Kjob" ]; then


         top=`grep -n "Leave Link    1" $i/1.out | head -1 | sed 's%:% %g' | awk '{print $1}'`

         extract-coords.sh $i/1.out > $i/coords
         extract-energy.sh $i/1.out >> $i/coords


# find the number of lines needed to perform the tail command to get NImag
          lines=$(expr `grep -n "Normal termination" $i/1.out |awk -F: '{print $1}' |tail -1` - `grep -n "/l9999.exe" $i/1.out |awk -F: '{print $1}' |tail -1`)

# unfortunately, NImag is not always on the same line
# use awk to put all of this onto one line, find NImag and replace any spaces with sed
          tail -n $lines $i/1.out |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \\ ' /NImag/ {for (i=1; i<=NF; i++) print $i;} /N  Imag/ {for (i=1; i<=NF; i++) print $i;} /NI  mag/ {for (i=1; i<=NF; i++) print $i;} /NIm  ag/ {for (i=1; i<=NF; i++) print $i;} /NIma  g/ {for (i=1; i<=NF; i++) print $i;} ' | sed 's/  //g' | grep "NImag" >> $i/coords
# get the number of basis functions
          grep NBasis $i/1.out| tail -n 1 | awk '{print $1 $2}' >> $i/coords

# put the route line into the coords file
          head -n $top $i/1.out |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \-\- ' /#/ {for (i=1; i<=NF; i++) print $i;} ' | sed 's/  //g' | grep "#" >> $i/coords

# put the name of the geometry into the coords file
          echo $j >> $i/coords
# put the whole path into the coords file
          echo `pwd`/$i >> $i/coords

# put the archive geom into the coords file
         printf "\nhere is the geometry from the archive\n" >> $i/coords
         xyz-no-freq.sh $i/1.out >> $i/coords

# check to see if the job was neither an optimization or freq; if not, then remove the coords file
# use sed to convert to all lowercase: sed 's/\(.*\)/\L\1/'
         if [ -z "`head -n $top $i/1.out |awk -F'\n' '{ORS=" "} {print $0}'| sed 's/\(.*\)/\L\1/' | awk -F \-\- ' / opt/ {for (i=1; i<=NF; i++) print $i;} / o  pt/ {for (i=1; i<=NF; i++) print $i;} / op  t/ {for (i=1; i<=NF; i++) print $i;} ' | sed 's/  //g' | grep " opt" `" ]\
         && [ -z "`head -n $top $i/1.out |awk -F'\n' '{ORS=" "} {print $0}'| sed 's/\(.*\)/\L\1/' | awk -F \-\- ' /freq/ {for (i=1; i<=NF; i++) print $i;} /f  req/ {for (i=1; i<=NF; i++) print $i;} /fr  eq/ {for (i=1; i<=NF; i++) print $i;} /fre  q/ {for (i=1; i<=NF; i++) print $i;}' | sed 's/  //g' | grep "freq" `" ]\
            ; then
          echo $i "is not an optimization or a freq"
          rm $i/coords
         fi

# check for command line arguments
         if [ -z "$1" ] && [ -z "$2" ] && [ $i = "./" ]; then
             echo "might want two command-line arguments because running in the current directory"
         elif [ -z "$2" ] && [ $i = "./" ]; then
             echo "Need one more command-line argument because running in the current directory"
#             if [ -f coords ]; then
#             rm coords
#             fi
         elif [ -n "$2" ] && [ $i = "./" ]; then
           if [ -f coords ]; then
            msi coords |grep Writing >& /dev/null
            if test -f coords-out.msi; then
              scp coords $USER@141.225.147.5:${1}/$2 >& /dev/null
               if [ $? -eq 0 ]; then
               success1="yes"
               fi
              scp coords-out.msi $USER@141.225.147.5:${1}/$2-out.msi >& /dev/null
               if [ "$success1" = "yes" ] && [ $? -eq 0 ]; then
                echo transferred $2 to leviathan:$1
                 else
                  echo transfer of $2 to $1 failed
               fi
            fi
           fi
         fi

# check for 1st command line argument
         if [ ! -f 1.out ]; then
           if [ -n "$1" ] && [ $i != "./" ]; then
             if test -f $i/coords; then
              msi $i/coords |grep Writing >& /dev/null
              if test -f $i/coords-out.msi; then
                scp $i/coords $USER@141.225.147.5:${1}/$j >& /dev/null
                 if [ $? -eq 0 ]; then
                 success1="yes"
                 fi
                scp $i/coords-out.msi $USER@141.225.147.5:${1}/$j-out.msi >& /dev/null
                 if [ "$success1" = "yes" ] && [ $? -eq 0 ]; then
#                  echo transferred $j to leviathan:$1
                  echo transferred $j
                 else
                  echo transfer of $j failed
                 fi
              fi
             fi
           fi
         else
          echo 1.out exists in current directory, nothing else will be transferred
         fi
        else
        echo kjob: $j 
        fi
       else
       echo job failed: $j
       fi
     elif [ -f $i/1.out ]; then
      echo empty file: $j
     fi
    fi
done
