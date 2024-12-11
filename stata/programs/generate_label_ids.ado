// label variables
capture program drop generate_label_ids
program generate_label_ids
	syntax varlist(min=1) [, STARTing(integer 1)]
	*
	if ("`starting'" == "") {
	  local starting 1
	}
	*
	foreach v of varlist `varlist' {
	  label variable `v' "`starting'"
		local starting = `starting' + 1
	}
	*
end
