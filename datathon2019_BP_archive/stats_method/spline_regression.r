library("bigrquery")
library("ggplot2")
# Shared project.
project_id <- "singapore-datathon-team"
#project_id <- "team02bloodpressure"
options(httr_oauth_cache=FALSE)
# Wrapper for running BigQuery queries.
run_query <- function(query){
  tb <- bq_project_query(project_id, query)
  return(bq_table_download(tb))
}
df <- run_query('
                SELECT * FROM `team_02.final_24hr`')
df1<-transform(df, gender = factor(df$gender,levels = c("Female", "Male"), labels = c(0,1)),actualhospitalmortality = factor(df$actualhospitalmortality,levels = c("ALIVE", "EXPIRED"), labels = c(0,1)))
df1<-df1[df1$age != "> 89",];
df1<- df1[-is.na(df1$age),];
df1 <- df1[grep("[[:digit:]]", df1$age), ]
  
#sum(is.na(df1$age), na.rm=TRUE)
#mean(as.integer(df1$age), na.rm=TRUE)
#[1] 61.92548
#df1<- replace(df1$age, is.na(df1$age), 61.92548)
hospmort <- df1$actualhospitalmortality;
aki<- df1$AKI;
gender <- df1$gender;
bmi<- df1$bmi;
ht <- df1$hypertension;
fb <- df1$nettotal;
b <- df1$ar_bp_sys;
apa<- df1$apache_iv;
vp<- df1$vaso_binary;
d<- df1$ar_bp_di;
m<- df1$ar_bp_mean;
mhr<- df1$medianHR;
age<- df1$age;
sepsis<- df1$sepsis_binary;
d1<- df1$COPD;
d2<- df1$angina;
d3<- df1$atrial_fibrillation;
d4<- df1$cancer;
d5<- df1$chf;
d6<- df1$coronary;
d7<- df1$diabetes;
d8<- df1$myocardial_infarction;
d9<- df1$renal_failure;
gammodel1<-gam(hospmort ~ age+gender+fb+ht+sepsis+vp+s(apa)+d1+d2+d3+d4+d5+d6+d7+d8+d9+s(m) ,data=df1,family=binomial)
summary(gammodel1)
par(mfrow=c(1,1))
plot(gammodel1, se=T, xlim=range(0:200), ylim=range(0:1),xlab="Median MBP", ylab="Hospital Mortality Rate", main="Keeping age, gender, FB, HT, SEPSIS, VASO, APA, DISEASES as controls (first 24 hours)");
#Plotting the Model
#par(mfrow=c(2,3)) #to partition the Plotting Window
gammodelwvp<-gam(hospmort ~ ht+fb+s(apa)+s(b) ,data=df1,family=binomial)
summary(gammodelwvp)
plot(gammodelwvp, se=T, xlab="Median SBP", ylab="Hospital Mortality Rate", main="Keeping hypertension, fluid balance and ApacheIV as controls")
#se stands for standard error Bands
#plot(gammodel1, se=T)
gammodel2<-gam(hospmort ~ fb+vp+s(apa)+s(b) ,data=df1,family=binomial)
summary(gammodel2)
par(mfrow=c(1,1))
plot(gammodel2, se=T, xlab="Median Systolic Blood Pressure", ylab="Hospital Mortality Rate", main="Keeping fluid balance and ApacheIV as controls")
gammodeldh<-gam(hospmort ~ ht+fb+vp+s(apa)+s(d) ,data=df1,family=binomial)
summary(gammodeldh)
par(mfrow=c(1,1))
plot(gammodeldh, se=T, xlab="Median Diastolic Blood Pressure", ylab="Hospital Mortality Rate", main="Keeping hypertension, fluid balance and ApacheIV as controls")
gammodeld<-gam(hospmort ~ fb+vp+s(apa)+s(d) ,data=df1,family=binomial)
summary(gammodeld)
par(mfrow=c(1,1))
plot(gammodeld, se=T, xlab="Median Diastolic Blood Pressure", ylab="Hospital Mortality Rate", main="Keeping fluid balance and ApacheIV as controls")
gammodelmh<-gam(hospmort ~ ht+fb+vp+s(apa)+s(m) ,data=df1,family=binomial)
summary(gammodelmh)
par(mfrow=c(1,1))
plot(gammodelmh, se=T, xlab="Median Mean Blood Pressure", ylab="Hospital Mortality Rate", main="Keeping hypertension, fluid balance and ApacheIV as controls")
gammodelm<-gam(hospmort ~ fb+vp+s(apa)+s(m) ,data=df1,family=binomial)
summary(gammodelm)
par(mfrow=c(1,1))
plot(gammodelm, se=T, xlab="Median Mean Blood Pressure", ylab="Hospital Mortality Rate", main="Keeping fluid balance and ApacheIV as controls")
################################
akimodelsh<- gam(aki ~ ht+fb+vp+s(apa)+s(b,df=3) ,data=df1,family=binomial)
summary(akimodelsh)
par(mfrow=c(1,1))
plot(akimodelsh, se=T, xlab="Median Systolic Blood Pressure", ylab="AKI", main="Keeping hypertension, fluid balance and ApacheIV as controls")
