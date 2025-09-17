#!/usr/bin/env python3
"""
script to plot probe counts across frames for each FG/each active site as violins
"""
import os, sys
import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from MD_batch_rin import *

pd.set_option('display.max_rows', 500)

parser = argparse.ArgumentParser(description='contact count violin plots for each active site')
parser.add_argument('-d',dest='d',nargs='*',help='directories to get counts from')
parser.add_argument('-o',dest='o',default=None,help='file name to save fig')

args = parser.parse_args()
workdirs = args.d

counts = {}
for s in ['A128','B256','C384']:
    for wd in workdirs:
        if not wd.endswith('/'): wd = wd + '/'
        with open(f'{wd}{s}-probe.batch_rawdf.pkl','rb') as fp:
            df = pickle.load(fp)
        df = df['p_tot']
        df.name = s+'_contacts'
        nd = {}
        for f in unique(list(df.index.get_level_values(0))):
            res = f.split(':')
            if res[0] == 'A':
                nd[f] = f'{res[2].replace("_SC",'')}_{res[1]}'
            elif f[0] == 'B':
                nd[f] = f'{res[2].replace("_SC",'')}_{int(res[1])-128}'
            elif f[0] == 'C':
                nd[f] = f'{res[2].replace("_SC",'')}_{int(res[1])-256}'
        df.index = pd.MultiIndex.from_tuples([(nd[i[0]],i[1]) for i in df.index])
        if s in counts.keys():
            counts[s] = pd.concat([counts[s],df],axis=0)
        else:
            counts[s] = df

df = pd.concat([counts['A128'],counts['B256'],counts['C384']],axis=1)
nf = len(df.index.levels[1])
df2 = df.fillna(0)
df2 = df2.groupby(level=0).agg(lambda x: list(x))
df2 = df2.map(lambda x: x+[0]*(nf-len(x)))
rk = df2.map(mean).mean(axis=1)
rk.sort_values(ascending=False,inplace=True)
df2 = df2.loc[rk.index,:]


# plot
d,r = np.divmod(len(df2.index.values),8)
if r:
    d += 1
fig, axs = plt.subplots(nrows=d,ncols=8,figsize=[16,3*d])
fig.tight_layout()
cols = ['tab:blue','tab:orange','tab:purple']
maxy = df2.map(max).values.max()
#nf = len(df2.iloc[0,0])
for i in range(0,len(df2.index.values)):
    loc = np.divmod(i,8)
    #filt = [v for v in df2.iloc[i,:] if not np.isnan(v)]
    #filt = [[v for v in df2.iloc[i,c] if not np.isnan(v)] for c in [0,1,2]]
    for j in [0,1,2]:
        #filt = [v for v in df2.iloc[i,j] if not np.isnan(v)]
        #if filt:
        #    parts = axs[loc[0],loc[1]].violinplot(filt,[j+1],showmedians=True)
        parts = axs[loc[0],loc[1]].violinplot(df2.iloc[i,j],[j+1],points=1000,showmedians=True)
        for pc in parts['bodies']:
            pc.set_facecolor(cols[j])
            pc.set_edgecolor(cols[j])
        for partname in ('cbars','cmins','cmaxes','cmedians'): #cmeans
            vp = parts[partname]
            vp.set_edgecolor(cols[j])
        #axs[loc[0],loc[1]].text(500,j+1,f'pf={len(filt)/nf}',color=cols[j],ha='center',fontsize='x-small')
    axs[loc[0],loc[1]].set_title(df2.index[i])
    axs[loc[0],loc[1]].set_xlim(0.5,3.5)
    axs[loc[0],loc[1]].set_ylim(0,maxy+10)
    axs[loc[0],loc[1]].set_xticks([1,2,3],labels=['A128','B256','C384'])
#fig.suptitle(f'dirs: {",".join(workdirs)}')
#plt.show()
if args.o:
    plt.savefig(args.o)
