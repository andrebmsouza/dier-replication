# Replication Files for Directional Information in Equity Returns
This repository contains replication files for the paper Directional Information in Equity Returns by [Luca Del Viva](https://sites.google.com/site/lucadelviva), [Carlo Sala](https://www.esade.edu/faculty/carlo.sala) and [Andre B.M. Souza](http://www.andrebmsouza.com). The paper will be available soon in SSRN.

# Authors
[Luca Del Viva](https://sites.google.com/site/lucadelviva), [Carlo Sala](https://www.esade.edu/faculty/carlo.sala), and [Andre B.M. Souza](http://www.andrebmsouza.com).

# Software Requirements
This code requires Matlab, Stata, R, and access to a command prompt to run `.sh` files.

# Data requirements
This code assumes there exists files named `CRSP_Daily.dta` and `CRSP_Monthly.dta` in `data/inputs`. These files should be downloaded from CRSP.

# Instructions
To construct the probability score, run the script `ConstructProbScore.sh` in the folder `code`.
Alternatively, you can run the scripts `Preparing_Daily_Variables.do`,`Preparing_Weekly_Variables.do`,`Preparing_Monthly_Variables.do`, `Aggregate_Data.do`, `Create_ProbScore_OOS_Parallelized.R` and `Create_Main_Strategies.do`.
Once the probability score is constructed, you can run the analysis to replicate Tables 1 and 2 in the paper by running the script `RunAnalysis.sh`.

## Data

***Important Disclaimer:*** The data used in this study was downloaded from the following sources in April, 2023.

 - [CRSP_Daily](blank) from the WRDS (crsp_a_stock).
 - [CRSP_Monthly](blank) from the WRDS.
 - [Fama_French_Daily](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_daily_CSV.zip) from [Kenneth French's website](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html)
 - [Fama_French_Monthly](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/ftp/F-F_Research_Data_Factors_CSV.zip) from [Kenneth French's website](https://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html).

## Additional Resources
### [Replication files for **Understanding Momentum and Reversals** (Kelly, Moskowitz and  Pruitt, 2021)](https://sethpruitt.net/research/downloads/)

