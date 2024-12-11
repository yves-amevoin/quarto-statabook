//program to convert a data in memory to a md table, preferably pandoc

/*
output: the output file 
caption: The table caption
usevarnames: use the var names as heading
usevarlabels: use the var labels as heading

Default is to use the first note of the variable as heading and 
then variable label and finally variable name if no notes/label found.

nachar: A character for missings, default is "-"
Round: (rounding for numerics)
Space: The space to put at the end of each variable, normally you can ignore

All the in - memory data is converted to strings, and I really don't border about converting the dates and other weird formats.

usage:

sysuse auto, clear
kable

or 

sysuse auto, clear
kable, usevarnames

or 

sysuse auto, clear
kable, out("temp.md") caption("Auto table")


The code can be largely improved!
*/


capture program drop kable
program kable
	version 15
	//parameters are the file, the space to input
	syntax [, SPAce(numlist>0 integer) OUTput(string) ROUnd(real 0.01) CAPtion(string) USEVARNames USEVARLabels nachar(string)]
  
  
	//Number of variables
	if (_N == 0) {
		if ("`output'" != ""){
    	writenone "`output'" "`caption'"
    }
    else{
    	display as error "Empty data"
    	tempfile f
      writenone "`f'" "`caption'"
      read_file "`f'"
    }
	}
  else{
  	tempfile savedtable 
    quietly save "`savedtable'"
  	quietly ds
    local allvars `r(varlist)'
    convert_wisely `allvars', round(`round') `usevarnames' `usevarlabels'
    //ncol is the total number of variables
    local ncol : word count `allvars'
    if ("`nachar'" == "") {
      local nachar = "-"
    }
    //space is the space length for each of the column. need to update in near future
    local nval : word count `space'
    // Managing the default behaviour for the space by aligning the columns to maximum length
    if ("`space'" == ""){
      foreach v of local allvars{
          *First keep the length of the note
        local notel = "``v'[note1]'"
        local notel = ulength("`notel'")
        local typel: type `v'
        local typel = regexr("`typel'", "str", "")
        *now the space
        if (`typel' > `notel'){
          local space = "`space' " + "`typel'"
        }
        else{
          local space = "`space' " + "`notel'"
        }
      }
      local nval = `ncol'
    }
    else{
      if (`nval' == 1){
        local space: display _dup(`ncol') "`space' "
      }
    }
    
    //length greather than one: check the length with the corresponding data
    if (`ncol' != `nval' & `nval' != 1){
      display as error "Aborting, :( -- Number of space (`nval') != Number of vars in memory (`ncol')--"
      exit 3
    }

    tokenize "`allvars'"
    forvalues i=1/`ncol'{
      local allvars_`i' "``i''"
    }
    tokenize "`space'"
    forvalues i = 1/`ncol'{
      local space_`i' "``i''"
    }
    forvalues i = 1/`ncol'{
      add_data_space `allvars_`i'' `space_`i'' "`nachar'"
    }
    if ("`output'" != ""){
      write_data "`output'" "`space'" "`caption'"
    }
    else{
      // print on the console, write on a file and read the file to
      // avoid depending on the width of the console.
      tempfile f
      tempname myfile
      write_data "`f'" "`space'" "`caption'" "`footnote'"
      read_file "`f'"
    }
    use "`savedtable'", clear
  }
  
end


**# A little program to read a file 
capture program drop read_file
program read_file 
  args f
  tempname myfile
  file open `myfile' using "`f'", read
		file read `myfile' line
		while (r(eof) == 0) {
		  display as text `"`line'"'
			file read `myfile' line
		}
  file close `myfile'
end


**# convert wisely the data to string characters.
capture program drop convert_wisely
program convert_wisely
	syntax varlist [, ROUnd( real 0.01) usevarnames usevarlabels]
	foreach v of varlist `varlist' {
  	tempvar factv
    local savednote ``v'[note1]'
	//remove all the notes including the notes != from 1 
	// This will take in account usevarnames for strings.
	quietly note drop `v'
    if ("`usevarlabels'" == "") & ("`usevarnames'" != ""){
      local savednote `v'
    }
    else if ("`savednote'" == "") | ("`usevarlabels'" != ""){
    	local savednote : variable label `v'
    }
    
    if ("`savednote'" == "") {
    	// Default is to use variable name if no notes and no label are found
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
    	//Numeric you can change the rounding parameter
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
    note `v': `savednote'
	}
end

**# Write none to a file using a custom pandoc style
capture program drop writenone
program writenone
  args f  caption // just the file to write on and the caption of the table
  tempname myfile
  capture file close `myfile'
  quietly file open `myfile' using "`f'", write replace
  file write `myfile' "Table: `caption'" _n
  file write `myfile' _n
  file write `myfile' `":::{custom-style="Nonestyle"}"' _n
  file write `myfile' "None" _n
  file write `myfile' ":::"_n
  file write `myfile' _n
  file close `myfile'
end 

**# Write the data to a file
capture program drop write_data
program write_data
	args f space caption allvars footnote
	tempname myfile
	capture file close `myfile'
	quietly file open `myfile' using "`f'", write replace
	file write `myfile' _n
	file write `myfile' "Table: `caption'"
	file write `myfile' _n
	file write `myfile' _n
	*add heading and the data to myfile
	add_heading `myfile' "`space'"
	add_data `myfile'	"`space'"
	file write `myfile' _n
	file write `myfile' "`footnote'"
	quietly file close `myfile'
end

**#  add space to data
capture program drop add_data_space
program add_data_space
	args vari max nachar
	tempvar lvar
	local mm = `max' + 1
	quietly replace `vari' = "`nachar'" if `vari' == "."
	gen `lvar' = ulength(`vari')
	summarize `lvar', meanonly
	if (`r(max)' > `mm'){
		display as error "Increase the space for variable `vari', too small"
	}
	local pad: display _dup(`mm') " "
	quietly replace `vari' = `vari' + substr("`pad'", 1, `mm' - `lvar')
end

**# --- ADD HEADINGS TO THE FILE
capture program drop add_heading
program add_heading
	args myfile space
	quietly ds
	local allvars `r(varlist)'
	local ncol: word count `r(varlist)'

	tokenize "`space'"
	forvalues i=1/`ncol'{
	  local space_`i' ``i''
	}
	tokenize "`allvars'"
	forvalues i=1/`ncol'{
	  local v_`i' ``i''
	}
	//writing the first line
	add_separator `myfile' "`space'"
	file write `myfile' _n
	file write `myfile' "|"
	//add the space and write to the file
	forvalues i = 1/`ncol'{
		local mylab "``v_`i''[note1]'"
		local mylabl = ulength("`mylab'")
		local mm = `space_`i'' + 1
		if (`mylabl' > `mm'){
			display as error "Increase the space for var `v_`i''; too small"
		}
		local pad: display _dup(`mm') " "
		local mylab = trim("`mylab'") + substr("`pad'", 1, `mm' - `mylabl')
		file write `myfile' "`mylab'"
		file write `myfile' "|"
	}

	file write `myfile' _n
	local first_column : display _dup(`space_1') "="
	local first_column = "+" + ":" + "`first_column'"
	file write `myfile' "`first_column'"
	file write `myfile' "+"

	forvalues i=2/`ncol'{
	  local col: display _dup(`space_`i'') "="
		local col = "`col'" + ":" + "+"
		file write `myfile' "`col'"
	}
	file write `myfile' _n
end

**# convert data to the md table
capture program drop add_data
program add_data
  args myfile  space
  tempfile mytxt
  tempname myt
  quietly export delimited using "`mytxt'", delimiter("|") novar nolabel
  file open `myt' using "`mytxt'", read
  file read `myt' line
  while r(eof) == 0{
   file write `myfile' "|"
	 file write `myfile' "`line'"
	 file write `myfile' "|"
	 file write `myfile' _n
	 add_separator `myfile' "`space'"
	 file write `myfile' _n
	 file read `myt' line
  }
end

//--- add the separator for a line (grid tables)
capture program drop add_separator
program add_separator
	args myfile space
	quietly ds
  local ncol: word count `r(varlist)'
  tokenize "`space'"
  file write `myfile' "+"
  forvalues i = 1/`ncol'{
 	  local nb = ``i'' + 1
		local col: display _dup(`nb') "-"
		local col = "`col'" + "+"
		file write `myfile' "`col'"
	}
end
