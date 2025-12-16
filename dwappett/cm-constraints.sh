#!/bin/bash

# usage:
# get-cm-constraints.sh {model} {optional: format}
# prints constraints for C1-C9 and C5-O7 for constrained ts opt
# if gaussian, prints "at1 at2 F"
# if orca, prints "{ B at1-1 at2-1 C }"
# otherwise prints "atom = number"

# work out atoms
bond1a=$(awk '$4 == "COR" && $3 == "C1" {print $2}' $1)
bond1b=$(awk '$4 == "COR" && $3 == "C9" {print $2}' $1)
bond2a=$(awk '$4 == "COR" && $3 == "C5" {print $2}' $1)
bond2b=$(awk '$4 == "COR" && $3 == "O7" {print $2}' $1)

if [[ "$2" == "gau"* ]]; then
  echo "$bond1a $bond1b F"
  echo "$bond2a $bond2b F"
elif [[ "$2" == "orca" ]]; then
  echo "{ B $(( bond1a - 1 )) $(( bond1b - 1 )) C }"
  echo "{ B $(( bond2a - 1 )) $(( bond2b - 1 )) C }"
else
  echo "C1 = $bond1a"
  echo "C9 = $bond1b"
  echo "C5 = $bond2a"
  echo "O7 = $bond2b"
fi
