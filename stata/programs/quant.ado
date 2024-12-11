/* 
Quantitative variables program
==============================


This program creates tables on quantitative variables ready for publication. The
tables are saved in the outpout variable that could be provided by the user,
and you can compute the tables by values of a categorical variable.

Parameters:
============

output: the output file for the tabulation
format: the format in the computation
append: if the output file exists, do you want to append the current tabulation to previous data?
by: compute qualitative values by a categorical varlist.

fullresult, meanonly, medianonly: modify display for results (see details)

mxsep, medsep, mxbrack, medbrack: separators for showing results (see details)

Details:
==========

Display details
------------------
Full results write result: N, median (IQR) (min/max)
Mean only writes result: N, mean (SD)
Median only writes result: median (IQR) (min/max)

Separators
---------------------------------

mxsep: Min / Maximum separator, could be any given string, default is "/"
medsep: Separator for the IQR, could be any given string, default is ";"

mxbrack: use bracket to wrap (min/max). Default is parenthesis
mxparenth: use parenthesis to wrap IQR. Default is brackets.

Example
==========================================

sysuse auto, clear
*/


capture program drop quant
program quant
	version 15
	*Full results write result like N, median (IQR) (min/max)
	*Mean only writes result like - N, mean (SD)
	*Median only writes result like median (IQR) (min/max)
	
	syntax varlist(min=1 numeric) [if] , OUTput(string) [append BY(varlist max=1) FULLresult MEANonly MEDianonly ///
														FORMat(string) mxsep(string) medsep(string) MXBrack  ///
														MEDPARenth ADDTOTal]
	
	
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
	
	// separators --------------------------------------------------------------
	
	if ("`mxsep'" == "") {
		local mxsep = "/"
	}
	
	if ("`medsep'" == "") {
		local medsep = ";"
	}
	
	// mop and mcl are opening and closings for the minimum/maximum.
	// default are parenthesis
	
	local mop = "("
	local mcl = ")"

	if ("`mxbrack'" != ""){
		local  mop = "["
		local mcl  = "]"
	}
	
	// medop and medcl are opening and closings for IQR [p25 ; p75]
	// default are brackets.
		
	local medop = "["
	local medcl = "]"
	
	if ("`medparenth'" != ""){
		local medop = "("
		local medcl =  ")"
	}
	
	if ("`form'" == ""){
	   local form  "%9.1f"
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
			  * Working on full result first
				quietly summarize `v' if `touse' & `by' == `L', detail
				local med = string(`r(p50)', "`format'")
				local p25 = string(`r(p25)', "`format'")
				local p75 =  string(`r(p75)', "`format'")
				local min = string(`r(min)', "`format'")
				local max = string(`r(max)', "`format'")
				local mn = string(`r(mean)', "`format'")
				local sd = string(`r(sd)', "`format'")
				local nobs = `r(N)'
			
				
				local fpart "`nobs', "
				
				
				if ("`meanonly'" != "")  {
					local  quantval = " `mn' (`sd')"
				} 
				
				if ("`medianonly'" != "") {
					local quantval = "`med'  `medop'`p25' `medsep' `p75'`medcl'  `mop'`min' `mxsep' `max'`mcl'"
				}
				
				if ("`fullresult'" != "") {
					local quantval =  "`med' `medop'`p25' `medsep' `p75'`medcl'  `mop'`min' `mxsep' `max'`mcl'"
				}
				// Avoid regression with previous code
				if ("`fullresult'" == "") & ("`medianonly'" == "") & ("`meanonly'" == "") {
					local quantval =  "`med'  `medop'`p25' `medsep' `p75'`medcl'  `mop'`min' `mxsep' `max'`mcl'"
				}
				
				local lbl: variable label `v'
				post tmp ("`v'") ("`lbl'") ("`quantval'")
			}
			
			local lvlname : label `labname' `L'
			postclose tmp
			
			// append different values of the `by'
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
	
	if (("`by'" == "") | ("`by'" != "" & "`addtotal'" != "")){
	* Do not compute values base on categories
		tempfile posttotal
		capture postclose tmp
		quietly postfile tmp str32 variable  str2045 label str2045 value  using "`posttotal'", replace
		foreach v of varlist `varlist'{
			* Working on full result first
			quietly summarize `v' if `touse', detail
			local med = string(`r(p50)', "`format'")
			local p25 = string(`r(p25)', "`format'")
			local p75 =  string(`r(p75)', "`format'")
			local min = string(`r(min)', "`format'")
			local max = string(`r(max)', "`format'")
			local mn = string(`r(mean)', "`format'")
			local sd = string(`r(sd)', "`format'")
			local nobs = `r(N)'
		
			
			local fpart "`nobs', "
			
			
			if ("`meanonly'" != "")  {
				local  quantval = "`nobs', `mn' (`sd')"
			} 
			
			if ("`medianonly'" != "") {
				local quantval = "`med'  `medop'`p25' `medsep' `p75'`medcl'  `mop'`min' `mxsep' `max'`mcl'"
			}
			
			if ("`fullresult'" != "") {
				local quantval =  "`fpart' `med' `medop'`p25' `medsep' `p75'`medcl'  `mop'`min' `mxsep' `max'`mcl'"
			}
			// Avoid regression with previous code
			if ("`fullresult'" == "") & ("`medianonly'" == "") & ("`meanonly'" == "") {
				local quantval =  "`fpart' `med'  `medop'`p25' `medsep' `p75'`medcl' `mop'`min' `mxsep' `max'`mcl'"
			}
			
			local lbl: variable label `v'
			post tmp ("`v'") ("`lbl'") ("`quantval'")
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
