"""
This is a program written by Qianyi Cheng
at University of Memphis.
"""

import os, sys, re, filecmp
from numpy import *
import argparse
from read_write_pdb import *
from glob import glob

atom1, res_info1, tot_charge1 = read_pdb('%s'%sys.argv[1])
atom2, res_info2, tot_charge2 = read_pdb('%s'%sys.argv[2])

xyz1=[]
xyz2=[]

for i in range(len(atom1)):
    coord1 = [float(atom1[i][8]),float(atom1[i][9]),float(atom1[i][10])]
    xyz1.append(coord1)
    coord2 = [float(atom2[i][8]),float(atom2[i][9]),float(atom2[i][10])]
    xyz2.append(coord2)

xyz1 = array(xyz1)
xyz2 = array(xyz2)

avg_xyz = mean([xyz1,xyz2],axis=0)
for i in range(len(atom1)):
    atom1[i][8] = avg_xyz[i][0]
    atom1[i][9] = avg_xyz[i][1]
    atom1[i][10] = avg_xyz[i][2]

write_pdb('avg_pdbs.pdb',atom1,'test')
