rm(list=ls())
library(dplyr)
library(readstata13)
library(moments)
library(sandwich)
library(lmtest)
library(xtable)
library(plm)

star <- function(x){
  if( x < 0.01){
    out <- '{***}'
  } else if(x< 0.05) {
    out <- '{**}'
  } else if( x<0.1){
    out <- '{*}'
  } else{
    out <- '{}'
  }
  out
}

ff   <- read.dta13('../../data/All_Factors.dta')
# Load portfolios
data <- read.dta13('../../portfolios/Strategies.dta')
#colnames(ff) <- c('dateff','MKT','SMB','HML','RF','UMD','ym','STR','LTR','RMW','CMA')

data <- data[ !is.na(data$ProbScore) , ]
data$Direction <- (data$RET>0)
mean(data$ProbScore<0)*100
data$ProbScore[data$ProbScore<0] <- 0
data$ProbScore[data$ProbScore>1] <- 1
data$DirFcast <- data$ProbScore>0.5

### Table ###
coef.tbl <- t.tbl <- cbind.data.frame(matrix(NA,ncol=4,nrow=6))
### OLS ####
# Dir Dir
m1 = (lm(Direction ~ DirFcast, data=data))
nw1 <- NeweyWest(m1)
test  <- coeftest(m1,nw1)
stars <- sapply(1:nrow(test), function(w) star(test[w,4]))
coef.tbl[1:2,1] <- sprintf('$%.2f^%s$',test[,1]*100,stars)
t.tbl[1:2,1]    <- sprintf( '$(%.2f)$', test[,3])
# Dir PS
m2 = (lm(Direction ~ ProbScore, data=data))
nw2 <- NeweyWest(m2)
test  <- coeftest(m2,nw2)
stars <- sapply(1:nrow(test), function(w) star(test[w,4]))
coef.tbl[c(1,3),2] <- sprintf('$%.2f^%s$',test[,1],stars)
t.tbl[c(1,3),2]    <- sprintf( '$(%.2f)$', test[,3])
# RET Dir
m3 = (lm(RET ~ DirFcast, data=data))
nw3 <- NeweyWest(m3)
test  <- coeftest(m3,nw3)
stars <- sapply(1:nrow(test), function(w) star(test[w,4]))
coef.tbl[1:2,3] <- sprintf('$%.2f^%s$',test[,1]*100,stars)
t.tbl[1:2,3]    <- sprintf( '$(%.2f)$', test[,3])
# RET PS
m4 = (lm(RET ~ ProbScore, data=data))
nw4   <- NeweyWest(m4)
test  <- coeftest(m4,nw4)
stars <- sapply(1:nrow(test), function(w) star(test[w,4]))
coef.tbl[c(1,3),4] <- sprintf('$%.2f^%s$',test[,1],stars)
t.tbl[c(1,3),4]    <- sprintf( '$(%.2f)$', test[,3])

### FMB ####
uniq.dates = sort(unique(data$date))
coefs <- matrix(NA,nrow=length(uniq.dates),ncol = 8)
for (t in 1:length(uniq.dates)){
  coefs[t,1:2] = coef(lm(Direction ~ DirFcast, data=data[data$date==uniq.dates[t], ]))
  coefs[t,3:4] = coef(lm(Direction ~ ProbScore, data=data[data$date==uniq.dates[t], ]))
  coefs[t,5:6] = coef(lm(RET ~ DirFcast, data=data[data$date==uniq.dates[t], ]))
  coefs[t,7:8] = coef(lm(RET ~ ProbScore, data=data[data$date==uniq.dates[t], ]))
  cat(sprintf('%s \n',t))
}

# alphas
a.seq <- seq(1,8,2)
for (i in a.seq){
  mdl <- lm(coefs[, i] ~ 1)
  nw <- NeweyWest(mdl)
  test  <- coeftest(mdl,nw)
  if (i == 1 || i == 5){
    test[,1] = test[,1] * 100 
  } 
  stars <- sapply(1:nrow(test), function(w) star(test[w,4]))
  coef.tbl[4, (i+1)%/%2] <- sprintf('$%.2f^%s$',test[,1],stars)
  t.tbl[4, (i+1)%/%2]    <- sprintf( '$(%.2f)$', test[,3])
}
# betas
# Dir Dir
mdl <- lm(coefs[, 2] ~ 1)
nw <- NeweyWest(mdl)
test  <- coeftest(mdl,nw)
stars <- sapply(1:nrow(test), function(w) star(test[w,4]))
coef.tbl[5,1]   <- sprintf('$%.2f^%s$',test[,1]*100,stars)
t.tbl[5,1]    <- sprintf( '$(%.2f)$', test[,3])
# Dir PS
mdl <- lm(coefs[, 4] ~ 1)
nw <- NeweyWest(mdl)
test  <- coeftest(mdl,nw)
stars <- sapply(1:nrow(test), function(w) star(test[w,4]))
coef.tbl[6,2]   <- sprintf('$%.2f^%s$',test[,1],stars)
t.tbl[6,2]    <- sprintf( '$(%.2f)$', test[,3])
# RET Dir
mdl <- lm(coefs[, 6] ~ 1)
nw <- NeweyWest(mdl)
test  <- coeftest(mdl,nw)
stars <- sapply(1:nrow(test), function(w) star(test[w,4]))
coef.tbl[5,3]   <- sprintf('$%.2f^%s$',test[,1]*100,stars)
t.tbl[5,3]    <- sprintf( '$(%.2f)$', test[,3])
# RET PS
mdl <- lm(coefs[, 8] ~ 1)
nw <- NeweyWest(mdl)
test  <- coeftest(mdl,nw)
stars <- sapply(1:nrow(test), function(w) star(test[w,4]))
coef.tbl[6,4]   <- sprintf('$%.2f^%s$',test[,1],stars)
t.tbl[6,4]    <- sprintf( '$(%.2f)$', test[,3])

rownames(coef.tbl) <- c(paste0('ols',c('a','b1','b2')),paste0('fmb',c('a','b1','b2')))
colnames(coef.tbl) <- paste0('m',1:4)
# Create table
t1  <-  xtable(coef.tbl)
tstats <- print( xtable(t.tbl), include.rownames = FALSE, sanitize.text.function = identity, booktab=TRUE)
lines  <- print(t1, sanitize.text.function = identity,booktab=TRUE)
lines <- strsplit(lines,'\n')[[1]]
tstats <- strsplit(tstats,'\n')[[1]]
i=0
for( j in 9:14){
  i=i+1 
  lines[j] <- paste( gsub(sprintf('%s',rownames(coef.tbl)[i]), sprintf('&\\\\multirow{2}{*}{%s}',rownames(coef.tbl)[i]),lines[j]),
                     '& &', tstats[j],'[0.3em]')
}
lines[11] <- paste(lines[11],'\\midrule')
lines[c(8,15)] <- '\\midrule'

lines[9]  <- paste('\\multirow{6}{*}{OLS}',lines[9])
lines[12] <- paste('\\multirow{6}{*}{FMB}',lines[12])

lines[7] <- '& &\\multicolumn{2}{c}{$r_{i\\,t}^+$}&\\multicolumn{2}{c}{$r_{i\\,t}$}\\\\'
lines <- lines[5:16]
lines[1]  <- "\\begin{tabular}{l*{6}{x{2cm}}}"
lines[2] <- '\\midrule'
lines[4] <- '\\cmidrule(lr){3-4}\\cmidrule(lr){5-6}'
lines[5] <- gsub('olsa','Constant',lines[5],fixed = TRUE)
lines[6] <- gsub('olsb1','$\\mathbbm{1}\\{\\text{PS}>0.5\\}$',lines[6],fixed = TRUE)
lines[7] <- gsub('olsb2','${\\text{PS}}$',lines[7],fixed = TRUE)
lines[8] <- gsub('fmba','Constant',lines[8],fixed = TRUE)
lines[9] <- gsub('fmbb1','$\\mathbbm{1}\\{\\text{PS}>0.5\\}$',lines[9],fixed = TRUE)
lines[10] <- gsub('fmbb2','${\\text{PS}}$',lines[10],fixed = TRUE)
save.path <- '../../tables/tex'
name     <- 'Table_DirAcc'
fileConn <- sprintf('%s/%s.tex',save.path,name)
write(lines,fileConn)
