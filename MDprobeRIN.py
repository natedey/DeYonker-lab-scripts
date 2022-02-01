#!/bin/python
import sys, os
import concurrent.futures, subprocess, argparse, re, time
from collections import defaultdict

parser = argparse.ArgumentParser(description='Passes Probe over MD simulation PDBs')
parser.add_argument('-list', dest='listfile', help='list of MD simulation PDBs')
parser.add_argument('-seed', help='comma-separated integers indicating seed residue indices')
parser.add_argument('-save', default='MDcontacts.csv', help='name of csv savefile')
args = parser.parse_args()

starttime = time.time()

#Make sure all files exist
pdbfiles = open(args.listfile, 'r').readlines()
for pdb in pdbfiles:
    if os.path.isfile(pdb.strip()) == False: 
        print("File does not exist: ", pdb.strip())
        sys.exit()

def probepdb(seed, filename):
    #Generate probefile
    run = subprocess.Popen('/home/tsmmers1/git/RINRUS/bin/probe -MC -Quiet -NOTICKs -self "all" -unformated '+filename.strip()+' > '+filename.strip()+'.probe', shell=True)
    run.wait()
    
    #Analyze probefile
    with open(filename.strip()+".probe", "r") as probefile:
        seedres = [int(x) for x in seed.split(",")]
        waters = defaultdict(int)
        res = defaultdict(int)
        for line in probefile:
            if int(line[11:15]) in seedres and int(line[28:32]) in seedres: continue
            elif int(line[11:15]) in seedres and line[33:36] == "WAT":
                waters[int(line[28:32])] +=1
            elif int(line[11:15]) in seedres:
                res[line[33:36] + str(int(line[28:32]))] +=1
            elif int(line[28:32]) in seedres and line[16:19] == "WAT":
                waters[int(line[11:15])] +=1
            elif int(line[28:32]) in seedres:
                res[line[16:19] + str(int(line[11:15]))] +=1
    waters = {k:v for k,v in sorted(waters.items(), key=lambda item: item[1], reverse=True)}
    watstr = str()
    for i in range(0,len(waters.keys())):
        watstr = watstr + ",W" + str(i) + "," + str(waters[list(waters)[i]])
    resstr = filename.strip().split(".")[-1]+","+ ",".join([i + "," + str(res[i]) for i in res.keys()]) + watstr
    os.remove(filename.strip()+".probe")
    return resstr


masterres = []
mastercont = []
with concurrent.futures.ThreadPoolExecutor() as executor:
    results = executor.map(probepdb, [args.seed]*len(pdbfiles), pdbfiles)

    for result in results:
        for i in result.split(",")[1::2]:
            if i not in masterres: masterres.append(i)
        fg = [0] * len(masterres)
        for i in range(0,len(masterres)):
            if masterres[i] in result.split(",")[1::2]:
                fg[i] = result.split(",")[result.split(",").index(masterres[i])+1]
        fg.insert(0, result.split(",")[0])
        mastercont.append(fg)

savefile = open(args.save, "w")
savefile.write("model,"+",".join(masterres)+"\n")
for item in mastercont:
    if len(item) < len(masterres)+1:
        moditem = item + [0]*(len(masterres)+1-len(item))
        savefile.write(",".join(map(str, moditem))+"\n")
    else: savefile.write(",".join(map(str, item))+"\n")
savefile.close()

print("Time completed:", (time.time()-starttime))
