#!/bin/bash
# this script takes MOE database xyz files and writes cerius2 car files

if [ "$1" = "--help" ]; then
echo "This script generates car files from standard xyz format"
else
echo " "
fi

if [ ! -e "$1" ]; then
echo ".xyz file does not exist"
exit
fi

debug=0
output=$(echo $1 | sed 's%.xyz$%%g' | sed 's%.inp$%%g' | sed 's%.com$%%g' | sed 's%.gjf$%%g')
echo writing $output.car from $1

### VERY IMPORTANT - changes break point for arrays!!! no break on spaces
IFS=$'\n'

echo "!BIOSYM archive 3
PBC=OFF

!DATE Thu Jul 1 11:57:00 2010" > $output.car

# instead of trying to deal with the blanks with spaces, just 
# use sed to get rid of them
# sed -i 's/^[[:space:]]*$//g' input-file
# array of lines to read
#blank=(`grep -n '^[[:space:]]*$' $1 | sed 's/://g'`)

#echo $(( ${blank[2]} - ${blank[1]} - 2 ))
# molecular specification
#sec3=("`head -$(( ${blank[2]} )) $1 | tail -$(( ${blank[2]} - ${blank[1]} - 1 ))`")
sec3=("`awk 'NR>2{print}' $1`")
for item in ${sec3[*]}
do
    printf "%s\n" $item | awk '{printf "%-5s%15.9f%15.9f%15.9f XXX  ND     ?       %-2s  0.000\n", $1, $2, $3, $4, $1}' >> $output.car
#    printf "%s\n" $item | awk '{printf "%-5s%15.9f%15.9f%15.9f XXX  ND     ?       %-2s  0.000\n", $1, $2, $3, $4, $1}'
done

echo "end
end
" >> $output.car


if [ $debug == 1 ]; then
echo reading $(( ${blank[2]} - ${blank[1]} - 2 )) atoms from $1

for (( k = 1 ; k < ${#blank[*]} ; k++ ))
do
  echo blank$k is ${blank[k]}
done

for item in ${sec3[*]}
do
    printf "%s\n" $item
done
fi
