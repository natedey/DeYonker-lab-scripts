#!/bin/python
import sys, os
import subprocess, argparse 

parser = argparse.ArgumentParser(description='Generates and transfers PDBs of specified path(s). Paths without irc1/irc2 at the end require a template.pdb file in the directory')
parser.add_argument('-p', help='Path to directory on Leviathan', required=True)
parser.add_argument('-l', help='Either 1) Path of single directory containing 1.out to be transfered or 2) Name of file containing paths of directories to be processed', required=True)
args = parser.parse_args()

def checkexist(arg1):
    continue_check = True 
    #Operations if arg1 is a file
    if os.path.isfile(arg1):
        paths = open(arg1, 'r').readlines()
        paths = [os.path.abspath(x.strip()) for x in paths]
        #Check 1.out and template.pdbs exist
        for path in paths:
            if not os.path.isfile(path+"/1.out"):
                print("Error: 1.out file not found in ", path)
                continue_check = False
            if path.endswith('irc1') or path.endswith('irc2'):
                if not os.path.isfile(path.rsplit("/",1)[0]+"/template.pdb"):
                    print("Error: template.pdb file not found in ", path.rsplit("/",1)[0])
                    continue_check = False
            else:
                if not os.path.isfile(path+"/template.pdb"):
                    print("Error: template.pdb file not found in ", path)
                    continue_check = False
        if continue_check == False:
            sys.exit("No PDB files generated/transfered due to errors")
        return paths
    #Operations if arg1 is a directory
    else:
        path = os.path.abspath(arg1)
        if not os.path.isfile(path+"/1.out"):
            print("Error: 1.out file not found in ",path)
            continue_check = False
        if path.endswith('irc1') or path.endswith('irc2'):
            if not os.path.isfile(path.rsplit("/",1)[0]+"/template.pdb"):
                print("Error: template.pdb file not found in ", path.rsplit("/",1)[0])
                continue_check = False
        else:
            if not os.path.isfile(path+"/template.pdb"):
                print("Error: template.pdb file not found in ", path)
                continue_check = False
        if continue_check == False:
            sys.exit("No PDB files generated/transfered due to errors")
        return [path]


if __name__ == "__main__":

    #Check all path(s) exist and have proper 1.out/template.pdbs
    processdirs = checkexist(args.l)
    originwd = os.getcwd()

    for directory in processdirs:
        
        if directory.endswith('irc1') or directory.endswith('irc2'):
            checkname = directory.split("/")[-2]+"-"+directory.split("/")[-1]+"-out.pdb"
        else:
            checkname = directory.split("/")[-1]+"-out.pdb"

        #If proper file already in directory, then transfer it
        if os.path.isfile(directory+"/"+checkname):
            subprocess.run(["scp", directory+"/"+checkname, os.getlogin()+"@leviathan.memphis.edu:"+args.p])

        else:
            #Go to specified wd since gopt_to_pdb.py writes directly to it
            os.chdir(directory)
            if directory.endswith('irc1') or directory.endswith('irc2'):
                subprocess.run(["/home/"+os.getlogin()+"/git/DeYonker-lab-scripts/gopt_to_pdb.py", "-f", "-1", "-o", directory+"/1.out", "-p", directory.rsplit("/",1)[0]+"/template.pdb"])
                subprocess.run(["scp", checkname, os.getlogin()+"@leviathan.memphis.edu:"+args.p])

            else:
                subprocess.run(["/home/"+os.getlogin()+"/git/DeYonker-lab-scripts/gopt_to_pdb.py", "-f", "-1", "-o", directory+"/1.out", "-p", directory+"/template.pdb"]) 
                subprocess.run(["scp", checkname, os.getlogin()+"@leviathan.memphis.edu:"+args.p])

    #Return to original wd
    os.chdir(originwd)

            
        


