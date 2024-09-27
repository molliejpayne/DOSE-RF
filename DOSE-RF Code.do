************************************************************************
*                DOSE-RF Code, Mollie Payne, 18/09/2024                  *
************************************************************************
clear

************************************************************************
* Step One: Load Your Dataset  
************************************************************************

cd // Set the file destination
use // Use dataset

************************************************************************
* Step Two: Specify your variables
************************************************************************
global y "" //One outcome (continuous)
global x_r "" //List of variables that predict dosehat
global x_y "" //List of variables for outcome model
global s "" //Variable that indicates session attendance
global d "" //Treatment Variable

tab $s
global m "" //Maximum number of sessions


************************************************************************
* Step Three: Random Forest
* Run the code below. Numvars() should be the square route of the number of variables in your x_r list. If you specify 4 predictors of dose, change numvars to 2. You can change the number of iterations if you wish, this is the number of trees in the forest. 
************************************************************************

rforest $s $x_r if $d == 1, type(class) iterations(200) numvars(5)
predict dosehat

************************************************************************
* Step Four: Set up matrix
* This is where your results will be stored. There are three rows, one for the coefficient, the lower 95% CI and the upper 95% CI. Each column represents a session. The number of columns should be the same as 'm'.
************************************************************************
 matrix result = J(3, $m, .)
 matrix rownames result = beta ll95 ul95
 matrix colnames result = 1 2 3 4 5 6 7 8 9 10 


************************************************************************
* Step Five: Run analysis. 
* Simply run the code below, all results will be stored in a matrix and printed after 'matrix list result'
************************************************************************
        * Loop through the regressions
        forval i = 1/$m {
			count if dosehat == `i'
			if r(N)>1 {
            * Run the regression
            capture regress $y $d $x_y if dosehat == `i'
			scalar b`i' = _b[$d]
			scalar se`i' = _se[$d]
            * Store the coefficients in the matrix
           matrix result[1,`i'] = _b[$d]

            * Store the lower CI limit in the matrix
           matrix result[2,`i'] = _b[$d] - 1.96 * _se[$d]

            * Store the upper CI limit in the matrix
           matrix result[3,`i'] = _b[$d] + 1.96 * _se[$d]
			}
			else {
				// Insufficient observations, store missing values in the matrix
			scalar b`i' = .
			scalar se`i' = .
			}
		}
		
matrix list result


************************************************************************
* Step Six: View results in graph. 
* This command plots the values within the matrix. You can change ylabel(a(b)c) to edit the y axis, where a is the lower limit, c is the upper limit and b is the scale for the the tick labels
************************************************************************

coefplot matrix(result), ci((2 3)) vert ylabel(-6(1)1) yline(0) ytitle(Treatment Effect) title(Causal Treatment Effect at Each Session) xtitle(Session) name(coefplot_TE, replace) 

************************************************************************
* End of File :) 


