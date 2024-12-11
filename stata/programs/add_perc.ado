/*
This program adds percentage to a numeric variables, computed on 
a certain number (the denominator), using a given format. If
the denominator is absent, then the program uses the sample frame passed
while calling.

varlist:  the variables on which you want to compute the percentage
denominator: a numlist, the denominators for computing percentages must of
length one or length the number of variables.
form: the formating to use for the percentage, by default "%9.1f"

* Variables are REPLACED, so data could be lost if not used carefully.
*/


capture program drop add_perc
program add_perc
  syntax varlist(min = 1) [if] [, DENOMinators(numlist>0 integer) Form(string)]
  marksample touse, novarlist
  
  * fixing the format
  
  if ("`form'" == ""){
	  local form "%9.1f"
	}
  
  *replace the denominators by N
  if("`denominators'" == ""){
    quietly count if `touse'
    local denominators = r(N)
  }
  
  quietly ds
  local allvars r(varlist)
  
  *ensure the denomitors has same length as nvars
  local nbdenom : word count `denominators'
  local nbvar: word count `varlist'
  
  //First check that everything works fine for the denominator
  if(`nbdenom' != 1 & (`nbdenom' != `nbvar')){
    display as error "Number of denominators and number of variables does not match"
    exit 3
  }
  else{
    *duplicates the denomiators if required
    if (`nbdenom' == 1){
       local denominators: display _dup(`nbvar') " `denominators'"
    }
    
    tokenize "`denominators'"
    forvalues i=1/`nbvar'{
      local denom`i' =  ``i''
    }
    
    tokenize "`varlist'"
    forvalues i=1/`nbvar'{
      replace ``i'' = 0 if ``i'' == .
      tempvar perc
      gen `perc' = 100 * ``i'' / `denom`i''
      tempvar sperc
      gen `sperc' = string(`perc', "`form'"), before(``i'')
      quietly replace `sperc' =  string(``i'') + " (" + `sperc' + ")" 
      drop ``i''
      rename `sperc'  ``i''
    }
  }
end