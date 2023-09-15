#! /usr/bin

## Prepare variables in stata
echo "Starting data preparation..."
stata -b Preparing_Daily_Variables.do & stata -b Preparing_Monthly_Variables.do & stata -b Preparing_Weekly_Variables.do;
wait
echo "Data preparation done"
## Aggregate data
echo "Starting data aggregation"
stata -b Aggregate_Data.do;
wait
echo "Data aggregation done"
## Estimate ProbScore
echo "Starting ProbScore estimation"
Rscript Create_ProbScore_OOS_Parallelized.R;
wait
echo "ProbScore constructed"
## Create quantiles
echo "Creating deciles..."
stata -b Create_Main_Strategies.do;
echo "All Done!"
