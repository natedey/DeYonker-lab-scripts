#!/usr/bin/env python

import sys

myBool = False


with open(sys.argv[1], 'r') as myfile:
    for line in myfile.readlines():
        if "--------------------------------------------------------------------------------------------------------" in line:
            myBool = not myBool
            print ''
        elif myBool == True: 
            myList = line.split("    ")
            myList = [x.strip(' ') for x in myList]
            myList = list(filter(None, myList))
            if len(myList) > 1:
                if len(myList[0]) < 8:
                    print myList[0] + '\t' + '\t' + '\t' + myList[2]
                elif 8 <= len(myList[0]) < 16:
                    print myList[0] + '\t' + '\t' + myList[2]
                else:
                    print myList[0] + '\t' + myList[2]
            else:
                print ""
        elif "molecule" in line:
            myheader = line.split()
            print myheader[1]
            continue          
        else:
            continue
            
