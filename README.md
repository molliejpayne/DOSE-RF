# DOSE-RF
Dose Outcome using Stratified Estimation with Random Forest  <br/>
*Mollie Payne*

## Overview 
DOSE-RF is a novel two-stage procedure designed to estimate the causal effect of treatment dosage, specifically in scenarios where adherence to treatment (such as the number of psychotherapy sessions attended) varies among participants. This method extends traditional approaches by leveraging **Random Forest classification** to predict treatment adherence and using **Principal Stratification** to estimate the dose-response relationship without making strong assumptions about the shape of the dose-response function.

## Stage 1. Predict potential sessions for all participants using random forest
Firstly, we build a random forest classification model with all possible predictors of dose. In this model we specify the number of trees and the number of covariates within each random subset, within each tree. Between 64 and 128 trees are recommended. The square root of the total number of predictors in the model should be subset for each tree. We then take predictions from this model to predict a new variable, **dosehat**. This is the predicted potential sessions for the sample.
## Stage 2. Regress randomisation on outcome within each dose strata
We then specify *j* number of regressions, where *j* is the maximum number of sessions. Within each level of predicted session, we regress the effect of randomisation on outcome. This will tell us the effect of randomisation within each stratum of people who would attend *j* sessions. We can plot these coefficients to derive a dose curve. 
