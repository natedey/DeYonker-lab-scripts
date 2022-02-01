#!/usr/bin/env python3
"""
This is a script written by Qianyi Cheng
"""

from numpy import *
import argparse, os
from read_write_pdb import *
from rms import *

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Convert cerius.car file to pdb format and save it in working directory')
    parser.add_argument('-dir',dest='wdir',default=os.path.abspath('./'),help='working diretory')
    parser.add_argument('-car',dest='carf',default=None,help='Cerius.car file')
    parser.add_argument('-tmp',dest='tmpf',default=None,help='pdb template file')
    parser.add_argument('-out',dest='outf',default=None,help='save pdb file')
    
    args = parser.parse_args()
    wdir = args.wdir
    carf = args.carf
    tmpf = args.tmpf
    outf = args.outf

    car_xyz = genfromtxt('%s/%s'%(wdir,carf),skip_header=4,skip_footer=2,usecols=(1,2,3))
    tmp_pdb, res_info, tot_charge = read_pdb(tmpf)

    map, xyz_i = get_fatom(tmp_pdb)
    (c_trans,U,ref_trans) = rms_fit(xyz_i,car_xyz[map])
    car_n = dot( car_xyz-c_trans, U ) + ref_trans
    sel_atom = update_xyz(tmp_pdb,car_n)
    write_pdb(outf,sel_atom)
