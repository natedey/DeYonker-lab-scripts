#!/usr/bin/env python3
# script created DAW 2026-01-20
# in the DeYonker group at the University of Memphis
# extracts lists of frames where specified FG has contacts from MD_batch_rin.py output df
# super easy to do in python shell or jupyter notebook, this is just to simplify quick checks

import argparse
import pandas as pd
import os.path

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='get list of frames where FG has contacts')
    parser.add_argument('-pkl', dest='pkl', default='batch_rawdf.pkl', help='batch_rawdf.pkl file to extract from')
    parser.add_argument('-fg', dest='fg', default=None, help='FG')

    args = parser.parse_args()

    if os.path.isfile(args.pkl):
        print(f'reading rawdf from: {args.pkl}')
        df = pd.read_pickle(args.pkl)
        if args.fg and args.fg in df.index.levels[0]:
            print(f'frames where fragment {args.fg} has contacts:')
            print(df.loc[args.fg,'p_tot'])
            #print('\n'.join(list(df.loc[args.fg,:].index)))
        else:
            print(f'fragment "{args.fg}" not in df index!')
    else:
        print(f'file {args.pkl} does not exist!')
