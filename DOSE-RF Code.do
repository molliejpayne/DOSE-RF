************************************************************************
*                DOSE-RF Code, Mollie Payne, 17/03/2026                *
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
set seed . //Pick seed number
local B = . //Numer of bootstrap interations

************************************************************************
* Step Three: Random Forest
* Run the code below. Numvars() should be the square route of the number of variables in your x_r list. If you specify 4 predictors of dose, change numvars to 2. You can change the number of iterations if you wish, this is the number of trees in the forest. 
************************************************************************

di "Running random forest on original data"
rforest $s $x_r if $d == 1, type(class) iterations(1000) numvars(5)
predict dosehat_og

************************************************************************
* Step Four: Set up matrix and ger original estimates before bootrap. 
* This is where your results will be stored. There are three rows, one for the coefficient, the lower 95% CI and the upper 95% CI. Each column represents a session. The number of columns should be the same as 'm'.
************************************************************************
 matrix result = J(3, $m, .)
forval i = 1/$m {
		capture regress $y $d $x_y if dosehat == `i'
		if _rc == 0 matrix result[1,`i'] = _b[$d]
	}
drop dosthat_og


************************************************************************
* Step Five: Set up postfile for bootstrap
************************************************************************
tempfile bootresults
capture postclose handle
postfile handle dose iter beta using `bootresults', replace

************************************************************************
* Step Six: Bootstrap loop
************************************************************************

forval b = 1/`B'{
	if mod(`b',50) == 0 display "Bootstrap interation `b' of `B'"

	preserve
	bsample

	*Random forest on bootstrap sample
	capture drop dosehat
	rforst $s $x_r if $d == 1, type(class) iterations(1000) numvars(5)
	predict dosehat

	*Get treatment effects for each dose
	forval i = 1/$m {
		count if dosehat == `i'

		if r(N) > 1 {
			capture regress $y $d $x_y if dosehat == `i'

		if _rc == 0 {
			post handle (`i') (`b') (_b[$d])
			}
		else {
			post handle (`i') (`b') (.)
		}
	}
	else {
		post handle (`i') (`b') (.)
		}
	}

 restore
}
postclose handle
************************************************************************
* Step Seven: Load and process bootstrap results
************************************************************************
use `bootresults', clear

*Compute 95% confidence intervals
bysort dose: egen ll95 = pctile(beta), p(2.5)
bysort dose: egen ul95 = pctile(beta, p(97.5)

bysort dose: keep if _n == 1
sort dose

************************************************************************
* Step Eight: Create final matrix
This is where your results will be stored. Three rows: coefficient, 
lower 95% CI, upper 95% CI Each column represents a dose level.
************************************************************************
mkmat ll95, matrix(ll95_row)
mkmat ul95, matrix(ul95_row)
matrix ll95_row = ll95_row'
matrix ul95_row = ul95_row'

matrix final = (orig \ ll95_row \ ul95_row)
matrix rownames final = beta ll95 ul95
matrix colnames final = 1 2 3 4 5

matrix list final

************************************************************************
* Step Nine: View results in graph
This command plots the values within the matrix. Adjust ylabel() as needed.
************************************************************************
coefplot matrix(final), ci((2 3)) vert ///
    ylabel(-10(2)2) ///
    yline(0) ///
    ytitle("Treatment Effect") ///
    title("Causal Treatment Effect at Each Dose Level") ///
    xtitle("Dose") ///
    name(coefplot_TE, replace)

************************************************************************
di "End of file"


