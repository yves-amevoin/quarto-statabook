capture program drop compute_ci
program compute_ci
	syntax varlist(max = 1) [if] [, LEvel(numlist>0 max=1))]
	marksample touse
	if ("`level'" == ""){
		local level 95
	}
	quietly count if `touse'
	local N = r(N)
	
	quietly count if `varlist' == 1 & `touse'
	local n = r(N)
	local perc = 100 * `n' / `N'
	local perc = string(`perc', "%9.2f")
	
	quietly ci proportions `varlist' if `touse', exact level(`level')
	
	local lb = 100 * r(lb)
	local ub = 100 * r(ub)
	
	local lb = string(`lb', "%9.2f")
	local ub = string(`ub', "%9.2f")
	
	gen tab_`varlist' = "`n' (`perc'), [`lb' - `ub']"
end
	
	
	
