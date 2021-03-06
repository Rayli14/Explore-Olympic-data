
##setwd
cd="/Users/rli/Desktop/midterm/"
#library
library(readxl)
library(ggplot2)
library(mice)
library(wordcloud)
library(wordcloud2)
library(stringr)
library(tidyverse)
library(dplyr)
library(gridExtra)
library(lubridate)

#########################problem 2.1
OMD1=read_excel(paste(cd,"OlympicMedallists.xlsx",sep=""),sheet="OMDataset1")
OMD2=read_excel(paste(cd,"OlympicMedallists.xlsx",sep=""),sheet="OMDataset2")
###data size 
dim(OMD1)
dim(OMD2)
## the type of data and variables
str(OMD1)
str(OMD2)
#what's inside the data 
names(OMD1)
names(OMD2)
##NA
md.pattern(OMD1)
md.pattern(OMD2)
table(OMD1$Sport)
table(OMD2$Sport)
table(OMD1$Games)
table(OMD2$Edition)
###############problem 2.2
#Data cleaning
OMD1$Sport=str_squish(OMD1$Sport)
OMD1$CoutryCode=str_squish(OMD1$CoutryCode)
OMD1$CoutryCode=toupper(OMD1$CoutryCode)
OMD2$Sport=str_squish(OMD2$Sport)
OMD2$NOC=str_squish(OMD2$NOC)
OMD2$NOC=toupper(OMD2$NOC)
#Omit and deleting
OMD1<-na.omit(OMD1)
OMD2<-na.omit(OMD2)
OMD1<-OMD1[,-8]
#logistic error : cosidering the difference between sailing, rowing and Canoeing
OMD2$Sport[which(OMD2$Discipline=="Swimming")]="Swimming"
OMD2$Sport[which(OMD2$Sport=="Polo")]="Aquatics"
OMD2$Sport[which(OMD2$Sport=="Ice Hockey")]="Hockey"
OMD1$Sport[which(OMD1$Sport=="Canoeing")]="Canoe/Kayak"

#Basic Data 1 Edition, Event, NOC, Medal, Gender
Countb1<-OMD1[,-c(4,6,8)]
names(Countb1)<-c("Edition","Sport","Event","NOC","Medal","Result in seconds")
Countb1$Gender=word(Countb1$Event,-1)
Countb1$Event=word(Countb1$Event,1,-2)
Countb1=na.omit(Countb1)
Countb1$Group="OMD1"
Countb1#for result comparision
Count1_b<-Countb1[,-6]
Countb2<-OMD2[,-c(1,4,5,9)]
Countb2$Group="OMD2"
Countb<-rbind(Count1_b,Countb2)
names(Countb)<-c("Edition","Sport","Event","NOC","Medal","Gender","Group")
###################2.3: country/ sport/ year /gender
##Distribution of univariables
#Medal
p1=plotpolar(Count1_b$Medal,"DB1: Medal distribution")
p2=plotpolar(Countb2$Medal,"DB2: Medal distribution")
grid.arrange(p1,p2,ncol=2)
#Edition
g<-ggplot(Countb,aes(x=Group,y=Edition,color=factor(Group)))+
  geom_boxplot()+
  labs(title = "Boxplot: edition distribution")
g
#Sport

p1=plotpolar(Count1_b$Sport,"DB1: Sport distribution")
p2=plotpolar(OMD2$Sport,"DB2: Sport distribution")
grid.arrange(p1,p2)
#City distribution
citycount=OMD2%>%group_by(Edition,City)%>%distinct(Edition,City)
flipplotbar(citycount$City," City distribution")
#Gender
plotpolar(OMD2$Gender,"Gender distribution")
#Discipline 
flipplotbar(OMD2$Discipline," Discipline distribution")
##Select Countries
Count_NOC<-Countb%>%group_by(NOC)%>%summarise(num=n())
Num500Country<-Count_NOC%>%filter(num>500)#Choosing total medal>500
Num500Country<-Num500Country[order(Num500Country$num,decreasing = F),]
Num500Country<-Num500Country$NOC

##Multivariables
#plot 1
Count_NOC_Med<-Countb%>%group_by(Group,NOC,Medal)%>%summarise(num=n())
Count_NOC_Med<-filter(Count_NOC_Med,NOC%in%Num500Country)
Count_NOC_Med$Medal<-factor(Count_NOC_Med$Medal,levels=c("Bronze","Silver","Gold"))
Count_NOC_Med$NOC<-factor(Count_NOC_Med$NOC,levels =Num500Country )
g <- ggplot(Count_NOC_Med, aes(NOC, num, fill =Medal)) +
  geom_bar(position="stack",stat="identity",alpha = 0.7, show.legend = TRUE)+
  scale_fill_brewer(palette = "Blues") +theme_bw()+
  theme(plot.title  = element_text(hjust = 0.5))+coord_flip()+
  facet_grid(.~Group)+
  labs(x="Country",y="Number of Medals",title="Medals of Top 18 countries Divided by Medal")
g
#plot 2
Count_NOC_Gd<-Countb%>%group_by(Group,NOC,Gender)%>%summarise(num=n())
Count_NOC_Gd<-filter(Count_NOC_Gd,NOC%in%Num500Country)
Count_NOC_Gd$NOC<-factor(Count_NOC_Gd$NOC,levels =Num500Country)
g <- ggplot(Count_NOC_Gd, aes(NOC, num, fill=Gender)) +
  geom_bar(position="stack",stat="identity",alpha = 0.7, show.legend = TRUE)+
  theme_bw()+coord_flip()+
  theme(plot.title  = element_text(hjust = 0.5))+
  facet_grid(.~Group)+
  labs(x="Country",y="Number of Medals",title="Medals of Top 18 countries Divided by Gender")
g
#Plot 3  Recent performance for Top 5 Countries+CHN from 1984
#Cosidering the lack of records in 2012, remove it
T5<-c("USA","URS","AUS","ITA","GBR","CHN")
Count_NOC_E<-Countb%>%group_by(Group,NOC,Edition)%>%summarise(num=n())
Count_NOC_E<-filter(Count_NOC_E,NOC%in%T5)
Count_NOC_E<-Count_NOC_E[which(Count_NOC_E$Edition>=1984),]
Count_NOC_E<-Count_NOC_E[which(Count_NOC_E$Edition<=2008),]
Count_NOC_E$NOC<-factor(Count_NOC_E$NOC,levels =T5)
g <- ggplot(Count_NOC_E, aes(Edition,num,color=NOC)) +
  geom_line(alpha = 0.7, show.legend = TRUE)+
  theme(plot.title  = element_text(hjust = 0.5))+
  facet_grid(.~Group)+
  labs(x="Edition",y="Number of Medals",title="Medals of Top 5 Countries VS CHN From 1984 to 2008")
g
#Plot 4  change of performance in Athletics by year (Only on DB1,it has results)
Athletics<-Countb1[which(Countb1$Sport=="Athletics"),]
Athletics<-na.omit(Athletics)
Athletics_Event<-Athletics%>%group_by(Event,Edition,Gender)%>%summarise(Result=mean(`Result in seconds`))
g<-ggplot(Athletics_Event, aes(Edition,Result,color=factor(Gender))) +
  geom_line()+
  theme(plot.title  = element_text(hjust = 0.5))+
  facet_wrap(~Event,nrow=4)+
  labs(title="Changes of Performance for Different Events in Athletics")
g
#Plot 5 Polar chart For Chinese and American Sports
#be specific from 1984, when china first join in Olympic 
Medal_CHN1<-Countb[which(Countb$NOC=="CHN"),]
Medal_CHN1<-Medal_CHN1[which(Medal_CHN1$Group=="OMD1"),]
Medal_CHN1<-Medal_CHN1%>%group_by(Group,Sport)%>%summarise(num=n())
CHN_order1=Medal_CHN1[order(Medal_CHN1$num,decreasing = T),]
CHN_order1=CHN_order1$Sport
Medal_CHN1<-Countb[which(Countb$NOC=="CHN"),]
Medal_CHN1<-Medal_CHN1[which(Medal_CHN1$Group=="OMD1"),]
Medal_CHN1<-Medal_CHN1%>%group_by(Group,Gender,Sport)%>%summarise(num=n())
Medal_CHN1$Sport=factor(Medal_CHN1$Sport,levels = CHN_order1)
g1 <- ggplot(Medal_CHN1, aes(Sport, num,fill=factor(Gender))) +
  geom_bar(position = "stack",stat="identity",alpha = 0.7, show.legend = TRUE)+
  theme(plot.title  = element_text(hjust = 0.5))+
  coord_polar()+theme_minimal()+ylim(-100,230)+
  labs(x="Event",y="Number of Medals",title="DB1: Chinese Strongest Sports")
Medal_CHN2<-Countb[which(Countb$NOC=="CHN"),]
Medal_CHN2<-Medal_CHN2[which(Medal_CHN2$Group=="OMD2"),]
Medal_CHN2<-Medal_CHN2%>%group_by(Group,Sport)%>%summarise(num=n())
CHN_order2=Medal_CHN2[order(Medal_CHN2$num,decreasing = T),]
CHN_order2=CHN_order2$Sport
Medal_CHN2<-Countb[which(Countb$NOC=="CHN"),]
Medal_CHN2<-Medal_CHN2[which(Medal_CHN2$Group=="OMD2"),]
Medal_CHN2<-Medal_CHN2%>%group_by(Group,Gender,Sport)%>%summarise(num=n())
Medal_CHN2$Sport=factor(Medal_CHN2$Sport,levels = CHN_order2)
g2 <- ggplot(Medal_CHN2, aes(Sport, num,fill=factor(Gender))) +
  geom_bar(position = "stack",stat="identity",alpha = 0.7, show.legend = TRUE)+
  theme(plot.title  = element_text(hjust = 0.5))+
  coord_polar()+theme_minimal()+ylim(-200,400)+
  labs(x="Event",y="Number of Medals",title="DB2: Chinese Strongest Sports")
Medal_US1<-Countb[which(Countb$NOC=="USA"),]
Medal_US1<-Medal_US1[which(Medal_US1$Group=="OMD1"),]
Medal_US1<-Medal_US1[which(Medal_US1$Edition>=1984),]
Medal_US1<-Medal_US1%>%group_by(Group,Sport)%>%summarise(num=n())
US_order1=Medal_US1[order(Medal_US1$num,decreasing = T),]
US_order1=US_order1$Sport
Medal_US1<-Countb[which(Countb$NOC=="USA"),]
Medal_US1<-Medal_US1[which(Medal_US1$Edition>=1984),]
Medal_US1<-Medal_US1[which(Medal_US1$Group=="OMD1"),]
Medal_US1<-Medal_US1%>%group_by(Group,Gender,Sport)%>%summarise(num=n())
Medal_US1$Sport=factor(Medal_US1$Sport,levels = US_order1)
g3 <- ggplot(Medal_US1, aes(Sport, num,fill=factor(Gender))) +
  geom_bar(position = "stack",stat="identity",alpha = 0.7, show.legend = TRUE)+
  theme(plot.title  = element_text(hjust = 0.5))+
  coord_polar()+theme_minimal()+ylim(-100,230)+
  labs(x="Event",y="Number of Medals",title="DB1: American Strongest Sports")
Medal_US2<-Countb[which(Countb$NOC=="USA"),]
Medal_US2<-Medal_US2[which(Medal_US2$Group=="OMD2"),]
Medal_US2<-Medal_US2[which(Medal_US2$Edition>=1984),]
Medal_US2<-Medal_US2%>%group_by(Group,Sport)%>%summarise(num=n())
US_order2=Medal_US2[order(Medal_US2$num,decreasing = T),]
US_order2=US_order2$Sport
Medal_US2<-Countb[which(Countb$NOC=="USA"),]
Medal_US2<-Medal_US2[which(Medal_US2$Edition>=1984),]
Medal_US2<-Medal_US2[which(Medal_US2$Group=="OMD2"),]
Medal_US2<-Medal_US2%>%group_by(Group,Gender,Sport)%>%summarise(num=n())
Medal_US2$Sport=factor(Medal_US2$Sport,levels = US_order2)
g4 <- ggplot(Medal_US2, aes(Sport, num,fill=factor(Gender))) +
  geom_bar(position = "stack",stat="identity",alpha = 0.7, show.legend = TRUE)+
  theme(plot.title  = element_text(hjust = 0.5))+
  coord_polar()+theme_minimal()+ylim(-200,400)+
  labs(x="Event",y="Number of Medals",title="DB2: American Strongest Sports")
grid.arrange(g1,g3,ncol=2)
grid.arrange(g2,g4,ncol=2)
#Plot 6 Gold medals: US vs. CHN
T2<-c("USA","CHN")
Count_NOC_G<-Countb%>%group_by(Group,Edition,NOC,Medal)%>%summarise(num=n())
Count_NOC_G<-filter(Count_NOC_G,NOC%in%T2)
G1<-Count_NOC_G[which(Count_NOC_G$Group=="OMD1"),]
G2<-Count_NOC_G[which(Count_NOC_G$Group=="OMD2"),]
G1=G1[which(G1$Medal=="Gold"),]
G1<-G1[which(G1$Edition>=1984),]
G1<-G1[which(G1$Edition<=2008),]
g1 <- ggplot(G1, aes(Edition,num,color=NOC)) +
  geom_line(alpha = 0.7, show.legend = TRUE)+
  theme(plot.title  = element_text(hjust = 0.5))+
  labs(x="Edition",y="Number of Medals",title="DB1-Gold medals: US vs. CHN from 1984")
G2=G2[which(G2$Medal=="Gold"),]
G2<-G2[which(G2$Edition>=1984),]
G2<-G2[which(G2$Edition<=2008),]
g2 <- ggplot(G2, aes(Edition,num,color=NOC)) +
  geom_line(alpha = 0.7, show.legend = TRUE)+
  theme(plot.title  = element_text(hjust = 0.5))+
  labs(x="Edition",y="Number of Medals",title="DB2-Gold medals: US vs. CHN from 1984")
grid.arrange(g1,g2,ncol=2)
#Plot 7  Most successful athelete in China: Medal>=4
Ath1<-OMD1
Ath1$Gender=word(Ath1$Event,-1)
Ath1<-Ath1[,-c(3,6,8,9)]
names(Ath1)<-c("Edition","Sport","Athlete","NOC","Medal","Gender")
Ath2<-OMD2[,-c(1,4,8,9)]
Ath=rbind(Ath1,Ath2)
Ath=Ath%>%distinct()
Ath=Ath[which(Ath$NOC=="CHN"),]
Ath=Ath%>%group_by(Athlete,Sport,Gender)%>%summarize(num=n())
Ath=Ath[which(Ath$num>3),]
Ath=Ath[order(Ath$num),]
Ath$Athlete=factor(Ath$Athlete,levels = Ath$Athlete)
g1<- ggplot(Ath, aes(Athlete, num,fill=factor(Sport))) +
  geom_bar(stat="identity",alpha = 0.7, show.legend = TRUE)+
  theme(plot.title  = element_text(hjust = 0.5))+coord_flip()+
  labs(x="Athlete",y="Number of Medals",title="Most Successful Athlete in China")
g2<- ggplot(Ath, aes(Athlete, num,fill=factor(Gender))) +
  geom_bar(stat="identity",alpha = 0.7, show.legend = TRUE)+
  theme(plot.title  = element_text(hjust = 0.5))+coord_flip()+
  labs(x="Athlete",y="Number of Medals",title="Most Successful Athlete in China")
grid.arrange(g1,g2,ncol=2)