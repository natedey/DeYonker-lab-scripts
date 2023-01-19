#!/usr/bin/env python3
"""
This is a program written by Tejaskumar Suhagia in DeYonker Research Group
at University of Memphis.
Version 1.1
Date 6th june 2022
"""
from numpy import *
from read_write_pdb import *
from copy import *
import argparse
from read_write_pdb import *

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Create 1.fix gile from given pdb file')
    parser.add_argument('-pdb', dest='pdbf', default=None, help='pdb_to_treat')
    args = parser.parse_args()
    pdbf = args.pdbf
    fix = open('1.fix','w')
    fix.write('$hess')
    fix.write('\n')
    with open(pdbf) as f:
        lines = f.readlines()
        for i in lines:
            if (i.split()[-1]) == '-1':
                fix.write(("    scale mass: "+i.split()[1]+", 90000000"))
                fix.write('\n')
    fix.close()


