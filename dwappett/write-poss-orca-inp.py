#!/usr/bin/env python3
"""
Script created by Dr Domi Wappett
in the DeYonker lab at the University of Memphis
2026-03-12
creates goat/docker input files for POSS project
"""

import argparse
import os, os.path
import shutil

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='write basic orca input for goat/docker')
    parser.add_argument('-type', dest='type', default='GOAT-ENTROPY', help='job type: GOAT/GOAT-ENTROPY/GOAT-REACT/DOCKER, default GOAT-ENTROPY')
    parser.add_argument('-xyz', dest='xyz', default=None, help='xyz file to use')
    parser.add_argument('-m', dest='mult', default=2, help='multiplicity of system, default 2')
    parser.add_argument('-c', dest='charge', default=0, help='charge of system, default 0')
    parser.add_argument('-guestxyz', dest='guestxyz', default=None, help='xyz file of guest (for docker calcs only)')
    parser.add_argument('-guestnum', dest='guestnum', default=None, help='number of guests to add (for docker calcs only)')
    parser.add_argument('-guestcharge', dest='guestcharge', default=None, help='charge of guest (for docker calcs only)')
    parser.add_argument('-guestmult', dest='guestmult', default=None, help='multiplicity of guest (for docker calcs only)')
    parser.add_argument('-maxtopodiff', dest='maxtopodiff', default=None, help='maxtopodiff keyword (for goat-react only)')
    args = parser.parse_args()

    palline = '%pal nprocs 20 end'
    maxcoreline = '%MaxCore 2000'
    scfline = '%scf Maxiter=350 end'
    xyzline = f'* xyzfile {args.charge} {args.mult} {args.xyz}'

    if args.type.upper() in ['GOAT','GOAT-ENTROPY','GOAT-REACT']:
        inpline = f'! XTB {args.type.upper()} SmallPrint TightSCF Slowconv UNO UCO DIIS'
        goatlines = '%goat\n align true'
        if args.type.upper() == 'GOAT-REACT' and args.maxtopodiff:
            goatlines = goatlines + f'\n maxtopodiff {args.maxtopodiff}'
        goatlines = goatlines+'\nend'
        inpcontents = [inpline, palline, maxcoreline, scfline, goatlines, '', xyzline]
    elif args.type.upper() == 'DOCKER':
        inpline = '! XTB SmallPrint TightSCF Slowconv UNO UCO DIIS'
        dockerlines = f'%DOCKER\n GUEST \"{args.guestxyz}\"'
        if args.guestcharge:
            dockerlines = dockerlines + f'\n GUESTCHARGE {args.guestcharge}'
        if args.guestmult:
            dockerlines = dockerlines + f'\n GUESTMULT {args.guestmult}'
        if args.guestnum:
            dockerlines = dockerlines + f'\n NREPEATGUEST {args.guestnum}'
        dockerlines = dockerlines+'\nEND'
        inpcontents = [inpline, palline, maxcoreline, scfline, dockerlines, '', xyzline]
    
    with open('orca.inp','w') as inpf:
        for line in inpcontents:
            inpf.write(line+'\n')    

    # copy job file
    jobfile = os.path.expanduser('~/git/DeYonker-lab-scripts/dwappett/1-orca-poss-goat')
    pwd = os.getcwd()
    shutil.copy(jobfile,f'{pwd}/1')



