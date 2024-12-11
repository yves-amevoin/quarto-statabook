
**# convert wisely the data to string characters.
* This program convert some in-memory data to character data keeping
* labels for categorical variables and rounding numeric variables. 
* This is a short and in helping for generating a pandoc style table.

capture program drop convert_wisely
program convert_wisely
	syntax varlist [, ROUnd(real 0.01) usevarnames]
	foreach v of varlist `varlist' {
  	tempvar factv
    local savednote ``v'[note1]'
	//remove all the notes including the notes != from 1 
	// This will take in account usevarnames for strings.
	quietly note drop `v'
    if ("`savednote'" == "") | ("`usevarnames'" != "") {
      	local savednote `v'
    }
    
   //first the coded variables (factors are my target)
	local lbl: value label `v'
	if (!missing("`lbl'")){
    decode `v', generate(`factv')
		drop `v'
		gen `v' = `factv'
  }
  else{
    capture confirm numeric variable `v'
    if (!_rc){
      gen double `factv' = round(`v', `round')
      quietly tostring `factv', replace force
          drop `v'
          gen `v' = `factv'
    }
    else{
      // sure string variable, I want to keep the order in the data
         gen `factv' = `v'
         drop `v'
         gen `v' = `factv'
    }
    
  }

	//Numeric you can change the rounding parameter

    note `v': `savednote'
	}
end
