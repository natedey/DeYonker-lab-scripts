#!/bin/bash
# CEW 10/22/2013
# usage:
#
# route.sh (arg1)
#
## the script will give the route line from the output file

bindir=bin
script_name=route

if [ "$1" = "--help" ]; then
echo "This script will print the route line from GXX output files

$script_name.sh (arg1)
if no arg1 is given, all 1.out files are searched

arg1 can be a single file

if arg1 is \"-f\", then arg2 must be a string to use in a find command
this string must be in quotes  or it must be properly escaped
e.g.,

$script_name.sh -f \"1-fail?\"
OR
$script_name.sh -f 1-fail\?
will search all 1-fail? files

$script_name.sh -f \"*.out\"
OR
$script_name.sh -f *\\.out
will search all .out files

$script_name.sh './temp* -name 1.out -o -name 1-fail\*'
will use the all command line arguments for a find command in directory named temp/*
and search for any files named 1.out and 1-fail\*
**note** the single quotes are required!

$script_name.sh '-name 1.out -o -name 1-fail\*'
will use the all command line arguments for a find command in the current directory
and search for any files named 1.out and 1-fail\*
**note** the single quotes are required!
"
exit
elif [ "$1" = "--config" ]; then
echo "# here is the default config file for $script_name.sh
# if it exists, it should be named ~/$bindir/$script_name.config
#
## flag:tab the value to use for the --tabs= in the expand command
tab 40
#
## flag:debug the debug level (0:1:2)
debug 0
#
## to comment out a flag, add a # before the flag
## to use the flag, remove the # before the flag
"
exit
fi

if [ -f ~/$bindir/$script_name.config ]; then
    echo using ~/$bindir/$script_name.config config file
    tab="`grep ^tab    ~/$bindir/$script_name.config | awk '{print $2}'`"
  debug="`grep ^debug  ~/$bindir/$script_name.config | awk '{print $2}'`"
else
    echo no config file found in ~/$bindir, using reasonable defaults
    tab=50
    debug=0
fi

if [ -z "$1" ]; then
 echo "processing all 1.out files in all subdirectories"

files=(`find ./ -type f -name 1.out`)

elif [ -n "$1" ] && [ "$1" == "-f" ]; then
 if [ -z "$2" ]; then
  echo you need a second command line argument to use in the find command
  exit
 fi
 echo "searching for \"$2\" files to process"
 files=(`find ./ -type f -name "$2"`)

elif [ -n "$1" ] && [ -f "$1" ]; then
 echo "processing $1 file"
 files="$1"
elif [ -n "`echo $@ | grep "./"`" ]; then
 echo expanding the command-line arguments to use in the find command
 echo "files=(\`find $@\`)"
 files=(`eval find $@`)
else
 echo expanding the command-line arguments to use in the find command
 echo "files=(\`find ./$@\`)"
 files=(`eval find ./$@`)
fi

if [ "${files[0]}" == "" ]; then
 echo something is wrong with the find results, exiting...
 exit
fi

 for (( i = 0 ; i < ${#files[*]} ; i++ ))
 do

# if not a gaussian file, don't process it
isoutputfile=`head -1 ${files[i]} | cut -f1 -d,`
if [ "$isoutputfile" == " Entering Gaussian System" ]; then

# find out the line number to which to process with head
 top=`grep -n "Leave Link    1" ${files[i]} | head -1 | sed 's%:% %g' | awk '{print $1}'`

 if [ -z "$top" ]; then
   top=`wc -l ${files[i]}|awk '{print $1}'`
 fi

# print the route line
 route_line=`head -n $top ${files[i]} |awk -F'\n' '{ORS=" "} {print $0}'| awk -F \-\- ' /#/ {for (i=1; i<=NF; i++) print $i;} ' | sed 's/  //g' | grep "#"`

 if [ $debug -ge 1 ]; then
  if [ "`tail -1 ${files[i]} |awk '{print $1, $2}'`" == "Normal termination" ]; then
   completion="completed:"
  else
   completion="failed:   "
  fi

# could generalize this script with this:
version="`grep -A1 " Cite this work as:" ${files[i]} |head -2| grep -v Cite |\
sed 's%Gaussian 09, Revision D.01%g09d01%g' |\
sed 's%Gaussian 09, Revision C.01%g09c01%g' |\
sed 's%Gaussian 09, Revision B.01%g09b01%g' |\
sed 's%Gaussian 09, Revision A.02%g09a02%g' |\
sed 's%Gaussian 03, Revision C.02%g03c02%g'`"

#  echo "$completion" GXX.version: "$version" for ${files[i]}
  echo "$completion" GXX.version: "$version" for ${files[i]}\; "$route_line" | sed 's%;%\t%' | expand -t, --tabs=$tab
 else
 echo ${files[i]}: "$route_line" | sed 's%:%\t%' | expand -t, --tabs=$tab
 fi

else
 if [ $debug -ge 2 ]; then
  echo ${files[i]} is not a Gaussian output file
  fi
fi

 done
