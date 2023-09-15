#! /usr/bin

## Directional Predictability Analysis --- Checked
echo "Directional Predictability..."
cd ../analysis/Directional_Predictability
Rscript Table_DirectionalAcc.R

## Portfolio Analysis --- Checked
echo "Portfolio Analysis..."
cd ../Univariate_Portfolio
Rscript Table_VWPSPortf.R

