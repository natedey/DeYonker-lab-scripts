#! /usr/bin/env python
import os, sys, glob
import concurrent.futures, subprocess, argparse, time
from collections import defaultdict

parser = argparse.ArgumentParser(description='Analyzes MD snapshots with Arpeggio to generate a Dynamic RIN')
parser.add_argument('-list', help='file containing list of names of MD snapshot PDBs to be analyzed')
parser.add_argument('-seed', nargs='+', help='seed selection written in format /A/301/ /A/302/ /A/303/CA ')
parser.add_argument('-noprox', action='store_true', help='if flag is given, will exclude proximal interactions')
parser.add_argument('-save', default='MDarpeggioFG_v2.dat', help='name of savefile')
args = parser.parse_args()

starttime = time.time()

#Make sure all files exist
pdbnames = [x.strip() for x in open(args.list, "r").readlines()]
for pdb in pdbnames:
    if os.path.isfile(pdb) == False:
        print("File does not exist: ", pdb.strip())
        sys.exit()

seedstr = " ".join(args.seed)

def arpeggiopdb(seedstr, filename):
    #Filter seed types
    seedpart = []
    seedwhole = []
    for s in seedstr.split():
        if len(list(filter(None, s.split("/")))) == 3: seedpart.append(s)
        elif len(list(filter(None, s.split("/")))) == 2: seedwhole.append(s)
    arpseed = " ".join(list(set(seedwhole + [x.rsplit("/",1)[0]+"/" for x in seedpart])))

    #Generate Arpeggio contactsfiles
    run = subprocess.Popen("cp "+os.getcwd()+"/"+filename+" temp"+filename.split("/")[-1].rsplit(".",1)[1]+".pdb", shell=True)
    run.wait()
    #Run Arpeggio -- note that display output is being redirected to /dev/null -- may consider redirecting to a logfile if there are errors in operating arpeggio
    run = subprocess.Popen('python3 /home/tsmmers1/git/arpeggio/arpeggio.py '+os.getcwd()+"/temp"+filename.split("/")[-1].rsplit(".",1)[1]+".pdb -s "+arpseed, shell=True, stdout=open(os.devnull,'w'), stderr=subprocess.STDOUT)
    run.wait()
    
    #Generate Seed Key and Identify Waters
    idwat = set()
    seedkey = {}
    with open("temp"+filename.split("/")[-1].rsplit(".",1)[1]+".pdb","r") as pdbfile:
        for line in pdbfile:
            if line[0:3] == "END": continue
            if line[17:20]=="HOH" or line[17:20]=="WAT": idwat.add("/"+line[21]+"/"+line[22:26].strip()+"/")
            if ("/"+line[21]+"/"+line[22:26].strip()+"/"+line[12:16].strip() in seedpart) or ("/"+line[21]+"/"+line[22:26].strip()+"/" in seedwhole):
                if line[17:20] in ['ARG','PHE','SER','PRO','TYR','ILE','GLU','LEU','ALA','VAL','ASP','HID','HIE','HIS','GLY','THR','LYS','ASN','MET','TRP','GLN','CYX','CYS','HD1','GU1','HD2','HD3','CS1']:
                    if line[12:16].strip() in ['C','O']:
                        seedkey['/'+line[21]+'/'+line[22:26].strip()+'/'+line[12:16].strip()] = '/'+line[21]+'/'+line[22:26].strip()+'-MC'
                    elif line[12:16].strip() in ['N','H']:
                        seedkey['/'+line[21]+'/'+line[22:26].strip()+'/'+line[12:16].strip()] = '/'+line[21]+'/'+str(int(line[22:26].strip())-1)+'-MC'
                    else: seedkey['/'+line[21]+'/'+line[22:26].strip()+'/'+line[12:16].strip()] = '/'+line[21]+'/'+line[22:26].strip()+'-SC'
                elif line[76:78].strip() in ['NA','MG','K','CA','MN','FE','CO','NI','CU','ZN']:
                    seedkey['/'+line[21]+'/'+line[22:26].strip()+'/'+line[12:16].strip()] = '/'+line[21]+'/'+line[22:26].strip()+'-M'
                else:
                    seedkey['/'+line[21]+'/'+line[22:26].strip()+'/'+line[12:16].strip()] = '/'+line[21]+'/'+line[22:26].strip()+'-L'
    
    #Analyze contacts file
    res = defaultdict(int)
    def FGtype(chain, res, atom):
        Catoms = ["C","O"]
        Natoms = ["N","H"]
        Matoms = ['NA','MG','K','MN','FE','CO','NI','CU','ZN']
        if atom in Matoms:
            return "/"+chain+"/"+str(res)+"-M"
        elif atom in Catoms:
            return "/"+chain+"/"+str(res)+"-MC"
        elif atom in Natoms:
            return "/"+chain+"/"+str(res-1)+"-MC"
        else:
            return "/"+chain+"/"+str(res)+"-SC"

    InteractType = { 0:'Clash', 1:'Cov', 2:'VdWClash', 3:'VdW', 4:'Prox', 5:'HBond', 6:'weakHbond', 7:'Halogen', 8:'Ionic', 9:'Metal', 10:'Aromatic', 11:'Hydro', 12:'Carbonyl', 13:'Polar', 14:'weakPolar'}

    with open("temp"+filename.split("/")[-1].rsplit(".",1)[1]+".contacts", "r") as contactfile:
        for line in contactfile:
            res1 = "/"+line.split()[0].rsplit("/",1)[0]+"/"
            res1a = line.split()[0].rsplit("/",1)[1]
            res2 = "/"+line.split()[1].rsplit("/",1)[0]+"/"
            res2a = line.split()[1].rsplit("/",1)[1]
            count = [int(x) for x in line.split()[2:17]]
            for i in range(0,len(count)):
                if count[i] !=0:
                    if args.noprox == True and i == 4: continue

                    chemint = InteractType[i]
                    
                    if res1 in set(seedwhole + [x.rsplit("/",1)[0]+"/" for x in seedpart]) and res2 in set(seedwhole + [x.rsplit("/",1)[0]+"/" for x in seedpart]): continue
                    elif (res1 in seedwhole and res2 in idwat) or (res1+res1a in seedpart and res2 in idwat):
                        res[seedkey[res1+res1a]+".W."+chemint] += count[i]
                    elif (res2 in seedwhole and res1 in idwat) or (res2+res2a in seedpart and res1 in idwat):
                        res[seedkey[res2+res2a]+".W."+chemint] += count[i]
                    elif res1 in seedwhole or res1+res1a in seedpart:
                        res2FG = FGtype(res2.split("/")[1], int(res2.split("/")[2]), res2a)
                        res[seedkey[res1+res1a]+"."+res2FG+"."+chemint] += count[i]
                    elif res2 in seedwhole or res2+res2a in seedpart:
                        res1FG = FGtype(res1.split("/")[1], int(res1.split("/")[2]), res1a)
                        res[seedkey[res2+res2a]+"."+res1FG+"."+chemint] += count[i]

    resstr = filename.split("/")[-1].rsplit(".",1)[1]
    for i in res.keys():
        resstr = resstr + "|" + i + "," + str(res[i])
            
    #Remove temp files
    for temp in glob.glob(os.getcwd()+"/temp"+filename.split("/")[-1].rsplit(".",1)[1]+".*"):
        os.remove(temp)

    return resstr

savefile = open(args.save, "w")
with concurrent.futures.ThreadPoolExecutor() as executor:
    jobs = []

    files_left = len(pdbnames)
    files_iter = iter(pdbnames)

    while files_left:
        for this_file in files_iter:
            job = executor.submit(arpeggiopdb, seedstr, this_file)
            jobs.append(job)
            if len(jobs) > 20:
                break

        for job in concurrent.futures.as_completed(jobs):
            files_left -= 1
            savefile.write(job.result() + "\n")
            jobs.remove(job)
            break
savefile.close()

print("Time completed:", (time.time()-starttime))
