#***************************************************************************
# Author: Andrew Skeen
# Title: graphs for activity transpose data
# Date: 05/04/16
#***************************************************************************

# Libs
require(ggplot2)
require(data.table)
require(sqldf)
require(plyr)
require(gridExtra)
#require(RPostgreSQL)
require(bit64)
require(gridExtra)
require(scales)
library(RPostgreSQL)
options(sqldf.driver = "SQLite")


setwd("/home/andrew/bimbo/")

test=fread('test.csv', data.table=T)
train=fread('train_0.csv', data.table=T)
#train1=fread('train_1.csv', data.table=F)


# multiples on client, product and week

multiples=train[,list("total"=.N), by=c("Cliente_ID","Producto_ID", "Semana")]
multiples[order(Cliente_ID,Producto_ID),]

train<-merge(train, multiples, by.x=c("Cliente_ID","Producto_ID", "Semana"), by.y=c("Cliente_ID","Producto_ID", "Semana"), all.x=F, all.y=F)
train<-train[total==1,,]

train<-train[order(Cliente_ID,Producto_ID, Semana)]
train[,`:=`(demand_m1=shift(Demanda_uni_equil, type="lag"), 
            sales_m1=shift(Venta_uni_hoy, type="lag"),
            ret_m1=shift(Dev_uni_proxima, type="lag")),by=c("Cliente_ID","Producto_ID")]

train[,`:=`(price=Venta_hoy/Venta_uni_hoy)]

a<-ggplot(data=train[runif(nrow(train),0,1)<0.1], aes(x=demand_m1, y=Demanda_uni_equil))+geom_point()
a


multiples=sqldf("select Cliente_ID, Producto_ID, Semana, sum(1) as total from train group by 1,2,3")

train<-sqldf("select a.* from train as a join multiples as b  on a.Cliente_ID=b.Cliente_ID and
             a.Producto_ID=b.Producto_ID and a.Semana=b.Semana where b.total=1")

train<-sqldf(c("create index idx on train(Cliente_ID, Producto_ID)", "select 
        a.*, b.Demanda_uni_equil as demand_m1, b.Venta_uni_hoy as sales_m1
from train as a join train as b on
a.Cliente_ID=b.Cliente_ID and 
a.Producto_ID=b.Producto_ID  where a.Semana=b.Semana+1"))

train$change<-train$Demanda_uni_equil/train$demand_m1
train$change_s<-train$sales_m1/train$demand_m1

train$change_ind<-factor(ifelse(train$change_s>=1,0,1))

a<-ggplot(data=train, aes(x=change, y=change_ind))+geom_density(alpha=0.3)
a

#agg=sqldf("select Semana, Producto_ID, avg(Demanda_uni_equil) as demand from train group by 1,2")
agg<-ddply(train, .(Semana, Producto_ID), function(x){
  ret=log(quantile(x$change, seq(0,1,by=0.2), na.rm=T))
  names(ret)<-paste0("q_", 0:5)
  ret  
})

agg$Producto_ID<-as.factor(agg$Producto_ID)

agg<-melt(agg, id.vars=c("Semana", "Producto_ID"), measure.vars=paste0("q_", 0:5), variable.name="var", value.name="val")

a<-ggplot(data=agg, aes(x=Semana,y=val, col=var))+geom_line()+
  facet_wrap(~Producto_ID)
a

train$Semana<-as.factor(train$Semana)
train$Canal_ID<-as.factor(train$Canal_ID)

a<-ggplot(data=train[train$change<=quantile(train$change,0.99, na.rm=T),], aes(x=change, fill=Semana))+geom_density(alpha=0.3)+
  facet_wrap(~Canal_ID)
a


train$outlier<-0
train$outlier[train$change>quantile(train$change, 0.99, na.rm=T)]<-1

train$outlier<-as.factor(train$outlier)

train$log_sales<-log(1+train$Venta_uni_hoy)
train$log_returns<-log(1+train$Dev_uni_proxima)

a<-ggplot(data=train, aes(x=log_sales, fill=outlier))+geom_density(alpha=0.3)
a


a<-ggplot(data=train, aes(x=log_returns, fill=outlier))+geom_density(alpha=0.3)
a

nulls<-train[is.na(train$change),]





na.rm = 



a<-ggplot(data=agg, aes(x=Semana,y=demand, col=Producto_ID))+geom_line()
a

agg=prop.table(table(train$Semana, train$Demanda_uni_equil), margin=1)


Semana
train$Demanda_uni_equil



tt=test[test$Producto_ID==1284,]
