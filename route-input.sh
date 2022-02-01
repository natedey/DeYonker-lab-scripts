#!/bin/bash
# CEW 08/16/2011
# usage:
#
# route-input.sh (arg1)
#
## the script will give the route line from all input files
## in the current directory and all subdirectories
#
# print the route line
# grep "#" `find ./ -name 1.inp`
#
# default head_length=10; head -10 could cause issues if route line does not end before the 10th line

bindir=newbin
script_name=route-input

if [ "$1" = "--help" ]; then
echo "This script extracts the route line from GXX input files
$script_name.sh single_filename/directory_name
 will work on a single file or all 1.inp files within all subdirectories

$script_name.sh (arg1)
if no arg1 is given, all 1.out files are searched

arg1 can be a single file

if arg1 is \"-f\", then arg2 must be a string to use in a find command
this string must be in quotes  or it must be properly escaped
e.g.,

$script_name.sh -f \"*inp\"
OR
$script_name.sh -f *\\inp
will search all *inp files

$script_name.sh -name 1.inp -o -name 1-fail1-inp -o -name 1-fail2-inp
will use the all command line arguments for a find command in the current directory
and search for any files named 1.inp, 1-fail1-inp, and 1-fail2-inp

$script_name.sh ' -name 1.inp -o -name 1-fail\*-inp'
will use the all command line arguments for a find command in the current directory
and search for any files named 1.inp and 1-fail\*-inp
**note** the single quotes are required!

run \"$script_name.sh --config\" to print a reasonable route-input.config file
"
# globbing does not allow for wildcards in the find command without an eval
# to make this work below
# $script_name.sh '-name 1.inp -o -name 1-fail\*-inp'

exit
elif [ "$1" = "--config" ]; then
echo "# here is the default config file for $script_name.sh
# if it exists, it should be named ~/$bindir/$script_name.config
#
## flag:tab the value to use for the --tabs= in the expand command
tab 40
#
## flag:head the value to use for the head of the input file
head 10
#
## to comment out a flag, add a # before the flag
## to use the flag, remove the # before the flag
"
exit
fi

if [ -f ~/$bindir/$script_name.config ]; then
            tab="`grep ^tab  ~/$bindir/$script_name.config | awk '{print $2}'`"
    head_length="`grep ^head ~/$bindir/$script_name.config | awk '{print $2}'`"
else
    tab=40
    head_length=10
fi

#if [ -f "$1" ]; then
# files=("$1")
#else
# files=(`find ./"$@" -name 1.inp`)
#fi

if [ -z "$1" ]; then
 echo "processing all 1.inp files in all subdirectories"
 files=(`find ./ -name 1.inp`)

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
# set noglob
 echo "files=(\`find ./$@\`)"
 files=(`eval find ./$@`)
# unset noglob
# "set noglab" did not correct the issue, used eval to fix command line expansion
fi

if [ "${files[0]}" == "" ]; then
 echo something is wrong with the find results, exiting...
 exit
fi

for (( i = 0 ; i < ${#files[*]} ; i++ ))
 do
  route=`head -$head_length ${files[i]} | grep -n "#" | head -1| awk '{print $1}' | cut -f1 -d:`
  if [ -n "$route" ]; then
   blank=(`head -$head_length ${files[i]} | grep -n '^[[:space:]]*$' | sed 's/://g'`)
   after=$(( ${blank[0]} - $route -1 ))
   if [ $after -lt 0 ]; then
    echo are you sure that ${files[i]} is an input file?
    exit  
   fi
   route_text=`grep -A$after "#" ${files[i]} | tr "\\n" " " | sed 's%  % %'`
   echo ${files[i]}: $route_text | sed 's%:%\t%' | expand -t, --tabs=$tab
  else
   echo are you sure that ${files[i]} is an input file?
  fi
 done
