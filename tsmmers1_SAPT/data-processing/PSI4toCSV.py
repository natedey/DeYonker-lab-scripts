#!/usr/bin/env python

import os
import sys
import csv

if os.path.exists("1.out") == False:
    print("NO 1.out for " + os.getcwd())
    sys.exit()

f01 = open("1.out")
f1 = f01.readlines()
f01.close()

myBool = False
myHeader = ["Name1","Number1","Name2","Number2",]
myData = []

for i in range(len(f1)):
    line = f1[i]

#Print Res Pair info to myData
    if "molecule" in line:
        wholename = line.split()[1]
        res1 = wholename.split("_")[0]
        res2 = wholename.split("_")[1]
        lres1 = list(res1)
        lres2 = list(res2)
        myData.extend(["".join(lres1[0:3]),"".join(lres1[3:]),"".join(lres2[0:3]),"".join(lres2[3:])])        

#Detect when results are both obtained and concluded
    if "--------------------------------------------------------------------------------------------------------" in line:
        myBool = not myBool

#Extract SAPT info
    if myBool == True:
        mySAPT = line.split("    ")
        mySAPT = [x.strip(' ') for x in mySAPT]
        mySAPT = list(filter(None, mySAPT))
        if len(mySAPT) > 1:
            myHeader.extend([mySAPT[0]])
#            myData.extend([mySAPT[2]])
            myDatalist = list(mySAPT[2])
            myData.extend(["".join(myDatalist[:-11])])
            
#Write data to CSV
f02 = open("../SAPTResults.csv","a")
with f02:
    writer = csv.writer(f02)
#    writer.writerow(myHeader)
    writer.writerow(myData)
f02.close()

