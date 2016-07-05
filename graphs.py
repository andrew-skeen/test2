# -*- coding: utf-8 -*-
"""
Created on Mon Jul  4 11:46:42 2016

@author: andrew
"""


import re
import gzip as gz
import numpy as np
import pdb
import pymc3 as pm
import seaborn as sns

#import datetime
import pandas as pd

path="/home/andrew/bimbo/"

data=pd.read_csv(path+'train_4.csv')

data.rename(columns={'Demanda_uni_equil': 'demand'}, inplace=True)

days=data.Semana.unique()

# get demand lagged by one week
cols=['Cliente_ID', 'Producto_ID', 'Semana', 'Ruta_SAK', 'Agencia_ID', 'Canal_ID']
cols2=[c for c in cols if c!='Semana']
data.sort_values(cols2, inplace=True)

# full complement of days
day_cnt=data.groupby(cols2)['Semana'].agg({'cnt': lambda x: len(x) })
day_cnt.reset_index(inplace=True)
day_cnt['ind']=(day_cnt.cnt==len(days)).astype('int')
del day_cnt['cnt']

data=pd.merge(data, day_cnt, left_on=cols2, right_on=cols2, how='left')

data=data[data['ind']==1]

data['demand_m0']=data.demand
#data.rename(columns={'demand':'demand_m0'}, inplace=True)
for i in xrange(len(days)-1):
    data['demand_m%s'%(str(i+1))]=data.groupby(cols2)['demand_m0'].shift(i+1)
    data['demand_m%s'%(str(i))]=np.log(1+data['demand_m%s'%(str(i))])-np.log(1+data['demand_m%s'%(str(i+1))])

#dem_cols=[ d for d in data.columns if re.findall('demand',d)!=[]]
dem_cols=['demand_m%s' %str(s) for s in xrange(5)]
nulls=data[dem_cols].notnull().all(axis=1)

data=data[nulls]

data.to_csv(path+'graph.csv', header=True, index=False)


# graph

prod=data.Producto_ID.unique()

prod[0]

avg=data[data.Producto_ID==prod[0]][dem_cols].mean()





data['Demanda_uni_equil']=np.log(1+data['Demanda_uni_equil'])

data['demand_m1']=data.groupby([c for c in cols if c!='Semana'])['Demanda_uni_equil'].shift(1)
data['demand_ratio']=data['Demanda_uni_equil']-data['demand_m1']
data['null_flag']=((data.demand_ratio.isnull()) & (data.demand_ratio.isnull())).astype('int')

data['dr1']=data.groupby([c for c in cols if c!='Semana'])['demand_ratio'].shift(1)
data['dr2']=data.groupby([c for c in cols if c!='Semana'])['demand_ratio'].shift(2)

