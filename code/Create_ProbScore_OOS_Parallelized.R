rm(list=ls())
library(readstata13)
library(reshape2)
library(furrr)
plan(multisession, workers = 30)

data <- read.dta13('../data/Prediction_Dataset.dta', convert.dates = FALSE)

idx    <- sort(unique(data$ym))
permno <- unique(data$PERMNO)
ProbScore <- cbind.data.frame( matrix(NA, nrow=length(idx), ncol=length(permno)))
colnames(ProbScore) <-  permno
idx.oos <- idx[61:length(idx)]

createForecast <- function(data.train, data.test, index){
  ols <- lm(PRet ~ MN + WN + DN + MP + WP + DP + lag_market + 
              IVL, data = data.train)
  ols.fc <- predict(ols, newdata = data.test, type = 'response')
  out <- cbind.data.frame('PERMNO' = data.test$PERMNO,
                          'ym' = index, 
                          'ProbScore' = unname(ols.fc))
  return(out)
}

ProbScore  <- future_map_dfr(1:length(idx.oos),function(w) createForecast(data[ data$ym < idx.oos[w] & data$SampleEst==1 , ], # Training data
                                                                    data[ data$ym == idx.oos[w] , ],                    # Prediction required for these
                                                                    idx.oos[w]),                                        # Time index for which prediction was made
                       .progress = TRUE)
save.dta13(ProbScore,'../data/ProbScore.dta')
