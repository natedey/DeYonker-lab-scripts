# Title:    gopt_pdb_transfer_mod.py
# Author:   Reza Hemmati
# Created:  12/03/2021
# Modefied: 12/16/2021
#
# Original script: gopt_pdb_transfer.py written by, Thomas Summers
#
# This script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
#
## usage:  python3  ~/GIT_DeYonker/DeYonker-lab-scripts/gopt_pdb_transfer_mod.py -p /home/rhemmati/test_transfer_from_hpc -d ./


#!/bin/python
import sys, os
import subprocess, argparse

output_name = '1.out'


def readlastline(f):
    f.seek(-200, 2)                # Jump to the second last byte.
    while f.read(1) != b"\n":      # Until EOL is found.
        f.seek(-3, 1)              # Jump back, over the read byte plus one more.
    return f.readlines()           # Read all data from this point on.


def checkexist(arg1):
    continue_check = True

    #Operations if arg1 is a file
    if os.path.isfile(arg1):
        paths = open(arg1, 'r').readlines()
        print (paths)
        paths = [os.path.abspath(x.strip()) for x in paths]
        #Check 1.out and template.pdbs exist
        for path in paths:
            if not os.path.isfile(path + "/1.out"):
                print("Error: 1.out file not found in ", path)
                continue_check = False
            if path.endswith('irc1') or path.endswith('irc2'):
                if not os.path.isfile(path.rsplit("/", 1)[0] + "/template.pdb"):
                    print("Error: template.pdb file not found in ", path.rsplit("/", 1)[0])
                    continue_check = False
            else:
                if not os.path.isfile(path + "/template.pdb"):
                    print("Error: template.pdb file not found in ", path)
                    continue_check = False
        if continue_check == False:
           sys.exit("No PDB files generated/transfered due to errors")
        return paths
    #Operations if arg1 is a directory
    else:
        path = os.path.abspath(arg1)
        print (path)
        if os.path.isfile(path + '/' + output_name):
            with open(path + '/' + output_name, 'rb') as f:
                for line in readlastline(f):
                    if 'Normal'.encode() in line: ## Or use b'Normal'
                        #print (line)
                        print ('\n******************************************')
                        print ('1.out file exists and has finished successfully :))')
                        continue_check = False

        if continue_check:
                  sys.stderr.write ('The output file corrupted or has not been finished yet!\n')
                  sys.exit(1)

        if path.endswith('irc1') or path.endswith('irc2'):
            if not os.path.isfile(path.rsplit("/", 1)[0] + "/template.pdb"):
                print("Error: template.pdb file not found in ", path.rsplit("/", 1)[0])
                continue_check = False
        else:
            if not os.path.isfile(path + "/template.pdb"):
                print("Error: template.pdb file not found in ", path)
                continue_check = False
        if continue_check == False:
            print ("No PDB files generated/transfered due to errors")
        return [path]


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description = 'Generates and transfers PDBs of specified path(s). Paths without irc1/irc2 at the end require a template.pdb file in the directory')

    parser.add_argument('-path', help = 'Path to directory on Leviathan', required = True)

    parser.add_argument('-dirc', help = 'Either 1) Path of single directory containing 1.out to be transfered or 2) Name of file containing paths of directories to be processed', required = True)

    args = parser.parse_args()


    ## Check all path(s) exist and have proper 1.out/template.pdbs
    processdirs = checkexist(args.dirc)
    print ('processdirs', processdirs)

    originwd = os.getcwd()

    for directory in processdirs:
        if directory.endswith('irc1') or directory.endswith('irc2'):
            checkname = directory.split("/")[-2] + "-" + directory.split("/")[-1] + "-out.pdb"
        else:
            checkname = directory.split("/")[-1] + "-out.pdb"

        #If proper file already in directory, then transfer it
        if os.path.isfile(directory + "/" + checkname):
            subprocess.run(["scp", directory + "/" + checkname, os.getlogin() + "@leviathan.memphis.edu:" + args.path])

        else:
            #Go to specified wd since gopt_to_pdb.py writes directly to it
            os.chdir(directory)
            if directory.endswith('irc1') or directory.endswith('irc2'):
                subprocess.run(["/home/" + os.getlogin() + "/GIT_DeYonker/DeYonker-lab-scripts/gopt_to_pdb.py", "-f", "-1", "-o", directory + '/' + output_name, 'p', directory.rsplit("/", 1)[0] + '/template.pdb'])
                subprocess.run(["scp", checkname, os.getlogin() + '@leviathan.memphis.edu:' + args.path])
                          subprocess.run(["/home/" + os.getlogin() + "/GIT_DeYonker/DeYonker-lab-scripts/gopt_to_pdb.py", "-f", "-1", "-o", directory + '/' + output_name, 'p', directory.rsplit("/", 1)[0] + '/template.pdb'])
                subprocess.run(["scp", checkname, os.getlogin() + '@leviathan.memphis.edu:' + args.path])

            else:
                subprocess.run(["/home/" + os.getlogin() + "/GIT_DeYonker/DeYonker-lab-scripts/gopt_to_pdb.py", "-f", "-1", "-o", directory + '/' + output_name, 'p', directory + "/template.pdb"])
                subprocess.run(["scp", checkname, os.getlogin() + '@leviathan.memphis.edu:' + args.path])

    #Return to original wd
    os.chdir(originwd)
## END OF FILE
