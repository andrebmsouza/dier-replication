rm(list=ls())
library(dplyr)
library(readstata13)
library(moments)
library(sandwich)
library(lmtest)
library(xtable)

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
GetCoefs <- function(excrets, df){
  mdl   <- lm(excrets ~ df$mktrf + df$smb + df$hml)
  nw    <- NeweyWest(mdl)
  coefs <- coeftest(mdl,nw)
  out   <- c( sprintf('$%.2f^%s$',coefs[1,1]*100, star(coefs[1,4])),
              sprintf('$%.2f^%s$',coefs[2,1], star(coefs[2,4])),
              sprintf('$%.2f^%s$',coefs[3,1], star(coefs[3,4])),
              sprintf('$%.2f^%s$',coefs[4,1], star(coefs[4,4])) )
  out
}
GettStats <- function(excrets, df){
  mdl   <- lm(excrets ~ df$mktrf + df$smb + df$hml)
  nw    <- NeweyWest(mdl)
  coefs <- coeftest(mdl,nw)
  out   <- c( sprintf('(%.2f)',coefs[1,3]), sprintf('(%.2f)',coefs[2,3]), 
              sprintf('(%.2f)',coefs[3,3]), sprintf('(%.2f)',coefs[4,3]))
  out
}

ff   <- read.dta13('../../data/All_Factors.dta',convert.dates = FALSE)
data <- read.dta13('../../portfolios/Strategies.dta',convert.dates = FALSE)
data <- data[ !is.na(data$lag_mcap) , ]

out <- data %>% filter(!is.na(qsj_ps)) %>% group_by(ym, qsj_ps) %>% summarise( rets = weighted.mean(RET,lag_mcap),
                                                                               pret = mean(RET>0),
                                                                               top  = mean(qsj_rets==10),
                                                                               bot  = mean(qsj_rets==1),
                                                                               mcap = median(lag_mcap))
colnames(out)[2] <- 'qsj'
PRet_PS <- out %>% group_by(qsj) %>% summarise(Pret = mean(pret),
                                               Top = mean(top),
                                               Bot = mean(bot),
                                               Mcap = mean(mcap))

portfs <- cbind.data.frame( sapply(1:10, function(w) out$rets[ out$qsj == w]) )
portfs$hed <- portfs[,10] - portfs[,1]
portfs$ym  <- out$ym[ out$qsj == 10]
colnames(portfs)[1:10] <- paste0('p',1:10)
ps <- merge(ff, portfs)
## Panel A: HED Portfolio ####
rows   <- c('Alpha','mktrf','smb','hml',
            'rmw','cma',
            'umd','str','ltr',
            'me_q','r_ia_q','r_roe_q','r_eg_q',
            'T','Adj. R2','Vol','Ann. SR','Skew','Kurtosis')

cols   <- c('Raw returns','CAPM','FF3','FF5','FF5+UMD+S/L-TR','Q5','Q5+UMD+S/L-TR')

models <- list( c('hed','Alpha'),
                c('hed','Alpha','mktrf'),
                c('hed','Alpha','mktrf','smb','hml'),
                c('hed','Alpha','mktrf5','smb5','hml5','rmw5','cma5'),
                c('hed','Alpha','mktrf5','smb5','hml5','rmw5','cma5','umd','str','ltr'),
                c('hed','Alpha','mktrf_q','me_q','r_ia_q','r_roe_q','r_eg_q'),
                c('hed','Alpha','mktrf_q','me_q','r_ia_q','r_roe_q','r_eg_q','umd','str','ltr')
)

coef.tbl <- star.tbl <- t.tbl <- data.frame(matrix(NA, nrow=length(rows), ncol=length(models)))
rownames(coef.tbl) <- rownames(star.tbl) <- rownames(t.tbl) <-  rows
colnames(coef.tbl) <- colnames(star.tbl) <- colnames(t.tbl) <-  cols
ps <- cbind.data.frame(1, ps)
colnames(ps)[1] <- 'Alpha'

for( i in 1:length(models)){
  data_tmp <- ps[,models[[i]]]
  if (i == 4){
    colnames(data_tmp) <- c('hed','Alpha', 'mktrf','smb','hml','rmw','cma')
  } else if (i==5){
    colnames(data_tmp) <- c('hed','Alpha', 'mktrf','smb','hml','rmw','cma','umd','str','ltr')
  } else if (i==6){
    colnames(data_tmp) <-  c('hed','Alpha','mktrf','me_q','r_ia_q','r_roe_q','r_eg_q')
  } else if (i==7){
    colnames(data_tmp) <-  c('hed','Alpha','mktrf','me_q','r_ia_q','r_roe_q','r_eg_q','umd','str','ltr')
  }
  narows   <- sapply(1:nrow(data_tmp), function(w) any(is.na(data_tmp[w,])))
  data_tmp <- data_tmp[ !narows, ]
  mdl   <- lm( hed ~ 0 + . , data = data_tmp)
  nw    <- NeweyWest(mdl)
  betas <- coef(mdl)
  betas[1] <- betas[1]*100
  betas <- round(betas,2)
  test  <- coeftest(mdl,nw)
  stars <- sapply(1:nrow(test), function(w) star(test[w,4]))
  coef.tbl[names(betas),cols[i]]   <- sprintf('$%.2f^%s$',betas,stars)
  t.tbl[rownames(test),cols[i]]    <- sprintf( '$(%.2f)$', test[,3])
  star.tbl[rownames(test),cols[i]] <- sapply(1:nrow(test), function(w) star(test[w,4]))
  # Stats
  coef.tbl['T',cols[i]]        <- round( length(mdl$residuals),0)
  coef.tbl['Adj. R2',cols[i]]  <- format( round( summary(mdl)$adj.r.squared, 2), nsmall=2)
  coef.tbl['Vol',cols[i]]      <- format( round( sd(data_tmp$hed)*100,2), nsmall = 2)
  coef.tbl['Ann. SR',cols[i]]       <- format( round( sqrt(12)*(mean(ps$hed[!narows] - ps$rf[!narows])/sd(ps$hed[!narows])), 2), nsmall = 2)
  coef.tbl['Skew',cols[i]]     <- format( round( skewness(data_tmp$hed), 2), nsmall = 2)
  coef.tbl['Kurtosis',cols[i]] <- format( round( kurtosis(data_tmp$hed), 2), nsmall = 2)
}

## Create table ##
t1  <-  xtable(coef.tbl)
tstats <- print( xtable(t.tbl), include.rownames = FALSE, sanitize.text.function = identity, booktab=TRUE)
lines  <- print(t1, sanitize.text.function = identity,booktab=TRUE)
lines <- strsplit(lines,'\n')[[1]]
tstats <- strsplit(tstats,'\n')[[1]]
i=0
for( j in 9:21){
  i=i+1 
  lines[j] <- paste( gsub(sprintf('%s',rownames(coef.tbl)[i]), sprintf('\\\\multirow{2}{*}{%s}',rownames(coef.tbl)[i]),lines[j]),
                     '&', tstats[j],'[0.2em]')
}
lines[21] <- paste(lines[21],'\\midrule')

lines[7] <- '&\\multirow{2}{*}{Raw return}&
              \\multirow{2}{*}{CAPM}&
              \\multirow{2}{*}{FF3}&
              \\multirow{2}{*}{FF5}&
              {FF5+UMD\\newline+S/L-TR}&
              \\multirow{2}{*}{Q5}&
              {Q5+UMD\\newline+S/L-TR}\\\\'

lines[28] <- '\\midrule'
lines <- lines[5:which(lines=='\\end{tabular}')]
lines[1]  <- "\\begin{tabular}{l*{8}{x{2cm}}}"  
lines[2]  <- '\\midrule'
lines[19] <- gsub('Adj. R2','R$^2$',lines[19])

lines[6] <- gsub('mktrf','MKT',lines[6])
lines[7] <- gsub('smb','SMB',lines[7])
lines[8] <- gsub('hml','HML',lines[8])
lines[9] <- gsub('rmw','RMW',lines[9])
lines[10] <- gsub('cma','CMA',lines[10])
lines[11] <- gsub('umd','UMD',lines[11])
lines[12] <- gsub('str','STR',lines[12])
lines[13] <- gsub('ltr','LTR',lines[13])
lines[14] <- gsub('me_q','R$_{{ME}}$',lines[14])
lines[15] <- gsub('r_ia_q','R$_{{IA}}$',lines[15])
lines[16] <- gsub('r_roe_q','R$_{{ROE}}$',lines[16])
lines[17] <- gsub('r_eg_q','R$_{{EG}}$',lines[17])


save.path <- '../../tables/tex'
name     <- 'Table_VWPSPortf'
fileConn <- sprintf('%s/%s.tex',save.path,name)
write(lines,fileConn)

### Panel B: Decile Portfolios ####
ps_table <- data.frame(matrix(NA,ncol=11,nrow=17))
rownames(ps_table) <- c('Alpha','tAlpha','Beta','tBeta','SMB','tSMB','HML','tHML',
                                               'Vol','SR','Skew','Max','Min','PRET','TOP','BOT','MCAP')
colnames(ps_table) <- c(1:10, '$10-1$')

exc.rets <- cbind( ps[,(ncol(ps)-10):(ncol(ps)-1), ] - ps$rf, 'hed' = ps$hed)

ps_table[c(1,3,5,7),] <- sapply(1:ncol(exc.rets), function(w) GetCoefs(exc.rets[,w], ps))
ps_table[c(2,4,6,8),] <- sapply(1:ncol(exc.rets), function(w) GettStats(exc.rets[,w], ps))
ps_table[9,]  <- round( sapply(1:ncol(exc.rets), function(w) sd(exc.rets[,w]))*100, 2)
ps_table[10,1:10] <- round( sapply(1:10, function(w) sqrt(12)*(mean(exc.rets[,w])/sd(ps[,(35+w)]))), 2) # already excess returns
ps_table[10,11]  <- round( sqrt(12)*(mean(exc.rets$hed - ps$rf)/sd(ps$hed)), 2)
ps_table[11,]  <- round( sapply(1:ncol(exc.rets), function(w) skewness(exc.rets[,w])), 2)
ps_table[12,]  <- round( sapply(1:ncol(exc.rets), function(w) max(exc.rets[,w])), 2)
ps_table[13,]     <- round( sapply(1:ncol(exc.rets), function(w) min(exc.rets[,w])), 2)
ps_table[14:16, ] <- round( cbind( t(PRet_PS)[-c(1,5),],NA),2)
ps_table[17, ]    <- round( cbind( t(PRet_PS[,5]),NA),0)

### Create Table ###
dig = matrix(3,ncol=ncol(ps_table)+1,nrow=nrow(ps_table))
rownames(dig) <- rownames(ps_table)
dig["MCAP",] <- 0
### Table: ProbScore Deciles ###
t1     <- xtable(ps_table, digits = dig)
lines  <- print(t1, sanitize.text.function = identity,booktabs=TRUE,NA.string = '$-$')
lines  <- strsplit(lines,'\n')[[1]]

lines[10] <- gsub('tAlpha','',lines[10])
lines[12] <- gsub('tBeta','',lines[12])
lines[14] <- gsub('tSMB','',lines[14])
lines[16] <- gsub('tHML','',lines[16])

lines[9]  <- gsub('Alpha','\\\\multirow{2}{*}{Alpha}',lines[9])
lines[11] <- gsub('Beta','\\\\multirow{2}{*}{MKT}',lines[11])
lines[13] <- gsub('SMB','\\\\multirow{2}{*}{SMB}',lines[13])
lines[15] <- gsub('HML','\\\\multirow{2}{*}{HML}',lines[15])

lines[21] <- paste(lines[21],'\\midrule')
lines[22] <- gsub('PRET','Avg. Pos. Ret.',lines[22])
lines[23] <- gsub('TOP' ,'Avg. Winners',lines[23])
lines[24] <- gsub('BOT' ,'Avg. Losers',lines[24])
lines[25] <- gsub('MCAP','Avg. Market Cap',lines[25])
lines[c(10,12,14,16)] <- paste0(lines[c(10,12,14,16)],'[0.3em]')
lines[5] <- "\\begin{tabular}{cccccccccccc}"
lines <- lines[5:27]

save.path <- '../../tables/tex'
name     <- 'Table_Decile_Portfolios'
fileConn <- sprintf('%s/%s.tex',save.path,name)
write(lines,fileConn)
