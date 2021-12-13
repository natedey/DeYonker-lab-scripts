# Title:     prepare-list.py
# Author:    Reza Hemmati
# Created:   11/13/2021
# Modefied:  12/04/2021
#
#
# Usage: python3 prepare-list.py

import os, sys, subprocess
import os.path
import subprocess, argparse
import functools 


list_finished_files_new = []


def readlastline(f):
    f.seek(-200, 2)              # Jump to the second last byte.
    while f.read(1) != b"\n":    # Until EOL is found ...
        f.seek(-3, 1)            # Jump back, over the read byte plus one more.
    return f.readlines()         # Return all data from this point on.
    

file_name = '1.out'  # Name of output files
iprint = True
kprint = True

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description = 'Generates a list of normally finished jobs.')
    parser.add_argument('-path', help = 'Path to directory where the outputs are.', default = './')
    args = parser.parse_args()

    w_dir = args.path

    if os.path.isdir(w_dir):
        os.chdir(w_dir)
        #print (args.path)
        if os.path.isfile(file_name):
            with open(file_name, 'rb') as f:
                for line in readlastline(f):
                    if 'Normal'.encode() in line: ## Or use b'Normal'
                        #print (line)
                        #print ('\n')
                        list_finished_files_new.append(w_dir + file_name)
                        iprint  = False

        if iprint:
                  sys.stderr.write ('The output file corrupted or has not been finished yet!\n')
                  sys.exit(1)


    #print ('List of finished jobs are:')
    #print (list_finished_files_new)

    #current_path = os.path.dirname(os.path.realpath(__file__))
    os.chdir('/home/rhemmati/python_scripts/')    # This is the current directory

    #print (os.getcwd())

    if os.path.exists("list_files.txt"):
        l = [line.rstrip() for line in open('list_files.txt', 'r')]
        for s in l:
            for i in range(len(list_finished_files_new)):
                if s == list_finished_files_new[i]:
                    print ('\n============================================================')
                    print ('The file in this path exists in the finished files list.\n')
                    kprint = False

        if kprint:
            print ('\n============================================================')
            print ('This file does NOT exist in the finished files list\n')
            print ('Let us add it to the list.\n')
            fg = open('list_files.txt', 'a')
            for i in range(len(list_finished_files_new)):
                fg.write(list_finished_files_new[i])
                fg.write('\n')
            fg.close()


