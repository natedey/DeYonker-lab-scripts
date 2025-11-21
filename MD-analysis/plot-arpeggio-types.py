#!/usr/bin/env python3
"""
Script for plotting arpeggio interaction types across simulation
Created by DAW Oct 2025 for demonstrating MD analysis
Some of this is specific to the short CM simulation A/C active site - other examples might have more than these 8 interaction types for example! Be careful before using on other things.
"""

### import modules ###
import os, sys
import glob
import argparse
import pickle
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

### process arguments given to run this script ###
parser = argparse.ArgumentParser(description='plot arpeggio interaction types across the simulation')
parser.add_argument('-data',dest='d',help='dataframe pkl file to load data from')
parser.add_argument('-out',dest='o',default='arpeggio_types_across_run.png',help='file name to save fig')
args = parser.parse_args()


### read in data ###
with open(args.d,'rb') as fp:
    rawdf = pickle.load(fp)

### remove contact types that are never present ###
# the columns are the contact types, so this gets the list of contact types that have any non-zero values in their columns
ispresent = rawdf.columns[rawdf.any()].tolist()
# df.loc[index,columns] is command for extracting specific parts of dataframe
# here we want all rows (:) and only the "ispresent" columns
newdf = rawdf.loc[:,ispresent]

### reorganise this dataframe ###
# currently the rows are organised by functional group and frame, and the columns by contact type
# this reshapes the data so the functional group labels are on the columns with the contact types, and each row is one frame
newdf = newdf.unstack(level=0,fill_value=0)
newdf = newdf.swaplevel(0,1,axis=1)
newdf = newdf.sort_index(level=0,axis=1)
# change the row names from "2cht.xxxxx" to integers xxxxx which is easier for plotting
newdf.index = [int(i.split('.')[1]) for i in newdf.index.values]
# turn into yes/no data instead of actual counts: 1 if that group has that type of contact in that frame, 0 otherwise
newdf = newdf.astype('bool').astype('int')

### plotting prep ###
# get list of functional groups, exclude water, and sort them by number of frames with contacts
fgs = list(newdf.columns.levels[0])
fgs = [f for f in fgs if not f.endswith('WAT')]
nf = {f: sum(newdf.loc[:,(f,'a_tot')]) for f in fgs}
fgs = sorted(fgs, key = lambda x: nf[x], reverse=True)
# define list of full type names for figure labels
typelabels = ['weak polar','polar','hydrophobic','ionic','weak h-bond','h-bond','vdw','vdw clash']
# pick how many subplots you want on each line, and then calculate from the number of FGs how many rows are needed to fit all the plots
spwidth = 7
d,r = np.divmod(len(fgs),spwidth)
if r:
    d += 1

### plot ###
# using number of columns/rows of subplots determined before, size figure so that each subplot has roughly 3x2 ratio
fig, axs = plt.subplots(nrows=d,ncols=spwidth,figsize=(3*spwidth, 2*d))
fig.tight_layout()

# for each functional group
for i in range(len(fgs)):
    # extract the data for this functional group, replace 0s with NaNs so they're not plotted at all
    pltdf = newdf.loc[:,[c for c in newdf.columns if c[0] == fgs[i] and c[1] != 'a_tot']].replace(0,np.nan)
    # reorder the columns to "standard" order and multiply each column by a different value to separate them out on the y-axis
    pltdf = pltdf.loc[:,[(fgs[i],'a_vdwcl'),(fgs[i],'a_vdw'),(fgs[i],'a_hb'),(fgs[i],'a_whb'),(fgs[i],'a_ion'),(fgs[i],'a_hp'),(fgs[i],'a_polar'),(fgs[i],'a_wpol')]] * [8,6,7,5,4,3,2,1]
    # first seven plots go on the top line
    if i < 7:
        axs[0,i].plot(list(pltdf.index),pltdf)
        axs[0,i].set_title(fgs[i])
        axs[0,i].set_ylim(bottom=0,top=9)
        axs[0,i].set_xlim(0,20000)
        # the first one of the line gets y labels, others are removed for space
        if i == 0:
            axs[0,i].set_yticks(ticks=[1,2,3,4,5,6,7,8],labels=typelabels)
        else:
            axs[0,i].set_yticks(ticks=[])
    # next seven plots go on the next line
    elif i < 14:
        axs[1,i-7].plot(list(pltdf.index),pltdf)
        axs[1,i-7].set_title(fgs[i])
        axs[1,i-7].set_ylim(bottom=0,top=9)
        axs[1,i-7].set_xlim(0,20000)
        if i == 7:
            axs[1,i-7].set_yticks(ticks=[1,2,3,4,5,6,7,8],labels=typelabels)
        else:
            axs[1,i-7].set_yticks(ticks=[])
    # remaining plots go on the last line
    else:
        axs[2,i-14].plot(list(pltdf.index),pltdf)
        axs[2,i-14].set_title(fgs[i])
        axs[2,i-14].set_ylim(bottom=0,top=9)
        axs[2,i-14].set_xlim(0,20000)
        if i == 14:
            axs[2,i-14].set_yticks(ticks=[1,2,3,4,5,6,7,8],labels=typelabels)
        else:
            axs[2,i-14].set_yticks(ticks=[])

### save figure to file ###
plt.savefig(args.o)
