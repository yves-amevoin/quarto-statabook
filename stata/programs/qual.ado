/*
					Qualitative variables tabulations
================================================================================

This program creates tables on categorical variables ready for publication. The
tables are saved in the outpout variable that could be provided by the user,
and you can compute the tables by values of a categorical variable.

Parameters:
============

output: the output file for the tabulation
format: the format in the computation
append: if the output file exists, do you want to append the current tabulation to previous data?
by: compute qualitative values by a categorical varlist.

Examples:
===========

sysuse auto, clear
gen price_high = (price > 10000)
gen mpg_low = (mpg < 100)
sum price_high mpg_low, det 
label variable price_high "High prices"
label variable mpg_low "Low mpg"
bysort foreign: tab1 mpg_low price_high
qual price_high mpg_low, output("temp.dta") by(foreign)

use "temp.dta", clear
list

*/


capture program drop qual
program qual
  version 15
	syntax varlist(min=1) [if] , OUTput(string) [FORMat(string) append BY(varlist max=1) ADDTOTal]
	marksample touse, novarlist

	if ("`format'" == ""){
	  local format "%9.1f"
	}
	
	quietly count if `touse'
	local N = `r(N)'
	
	// output of the temporary file
	tempfile postoutput
	
	
	if ("`append'" != ""){
		confirm file "`output'"
	}
	
	* Compute values for each levels of a categorical variable

	if ("`by'" != ""){
		// check if the `by' variable is categorical:
		
		local labname: value label `by'
		
		if ("`labname'" == ""){
			display "`by' is not a categorical variable"
			exit 1
		}
		
		// Get the different values of the categorical variable
		
		
		levelsof `by', local(levels)
		local counter = 0
			
		foreach L of local levels {
		
			// foreach of the levels of the variable, compute the
			// summary of the variable.
			
			local counter = `counter' + 1
			// using postfile to improve the output
			tempfile postoutput`L'
			capture postclose tmp
			quietly postfile tmp str32 variable  str2045 label str2045 value_`L'  using "`postoutput'`L'", replace
			
			
			foreach v of varlist `varlist'{
			  quietly sum `v' if `touse' & `by' == `L' , detail
				local n_m = `r(sum)'
				local nobs = `r(N)'
				*the mean is sometimes empty
				local perc_m = 100 * (`n_m' / `nobs')
				local perc_m = string(`perc_m', "`format'")
				//If you have a dot, replace by 0
				if ("`perc_m'" == "."){
					local perc_m "0.0"
				}
				
				
				local qual = "`n_m' (`perc_m')"
				
				local lbl: variable label `v'
				post tmp ("`v'") ("`lbl'") ("`qual'")
			}
			
			local lvlname : label `labname' `L'
			postclose tmp
			
			preserve
			 quietly{
				if ("`counter'" == "1"){
						use "`postoutput'`L'", clear
						label variable value_`L' "`lvlname' (N = `nobs')"
						save "`postoutput'", replace
				}
				else{
					use "`postoutput'", clear
					quietly merge 1:1 variable label using "`postoutput'`L'"
					label variable value_`L' "`lvlname' (N = `nobs')"
					capture drop _merge
					save "`postoutput'", replace
				}
			 }
			restore
			
		}
		
	}
	
	if (("`by'" == "") | ("`by'" != "" & "`addtotal'" != "")) {
		
		tempfile posttotal
		capture postclose tmp
		
		quietly postfile tmp str32 variable  str2045 label str2045 value  using "`posttotal'", replace
		foreach v of varlist `varlist'{
		  quietly sum `v' if `touse' , detail
			local n_m = `r(sum)'
			local nobs = `r(N)'
			*the mean is sometimes empty
			local perc_m = 100 * (`n_m' / `nobs')
			local perc_m = string(`perc_m', "`format'")
			//If you have a dot, replace by 0
			if ("`perc_m'" == "."){
				local perc_m "0.0"
			}
			
			if ("`nobs'" == "`N'"){
			  local qual = "`n_m' (`perc_m')"
			}
			else{
			  local qual = "`nobs', `n_m' (`perc_m')"
			}
			
			local lbl: variable label `v'
			post tmp ("`v'") ("`lbl'") ("`qual'")
		}
		postclose tmp
		
		quietly{
			preserve
				if ("`addtotal'" != ""){
					use "`posttotal'", clear
					merge 1:1 variable label using "`postoutput'"
					label variable value "Total (N = `nobs')"
					capture drop _merge
					save "`postoutput'", replace
					
				}
				else{			
					use "`posttotal'", clear
					save "`postoutput'", replace
					
				}
			restore
		}
	}
	
	preserve
		// if append, add your data to the previous file
		if ("`append'" != ""){
			use "`output'", clear
			append using "`postoutput'"
		}
		else{
			use "`postoutput'", clear
		}
		
		label variable variable "Variables"
		label variable label "Variables labels"
		
		quietly save "`output'", replace
	restore
end
