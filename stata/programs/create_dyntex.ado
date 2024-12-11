capture program drop create_dyntex
* Create the dynamic document.
program create_dyntex

 syntax using/, dyntex_file(string) label_sheet(string) tab_dir(string) fig_dir(string) [nbinput(numlist > 0 integer max=1)]

	confirm file "`using'"
	tempvar myf
	tempfile temptable
	local section "&;#123)"
	local subsection "&;#123)"
	local mode "Portrait"

	capture file close `myf'
	file open `myf' using "`dyntex_file'", write replace
	file write `myf' "<<dd_version : 1>>"
	file write `myf' _n
	//load the excel file: the sheet for labelling
	quietly import excel using "`using'", sheet("`label_sheet'") firstrow clear
	capture tostring *, replace
	keep if InputID != ""
	if ( _N == 0 ){
	  display as error "No data in the Table's Label sheet provided"
		exit 3
	}
	gen nb = _n
	quietly save "`temptable'"

	if ("`nbinput'" == "") {
	  local nbinput = _N
	}
  
	forvalues i = 1/`nbinput' {
		quietly {
		  use "`temptable'", clear
			tostring *, replace
			keep if nb == "`i'"
		}
		local footnote = FootNote[1]
		local caption = Caption[1]
		local id = trim(InputID[1])
      //------------------- PORTRAIT OR LANDSCAPE?--------------------------------
      if (DisplayMode[1] != "`mode'" ) & (DisplayMode[1] != "") {
        if (DisplayMode[1] == "Landscape") {
            local newmode "Landscape"
        }
        else{
          *The default behaviour if the mode is something else is Portrait
          local newmode "Portrait"
        }
      }
      if ("`newmode'" != "`mode'") & ("`newmode'" != ""){
        file write `myf' "\Begin`newmode'"
        file write `myf' _n
        file write `myf' _n
        local mode "`newmode'"

        display as result "Changed to `mode' mode..."
      }
      //------------------- ADD THE SECTION AND SUBSECTION -----------------------
      if (Section[1] != "`section'") & (Section[1] != "") & (Section[1] != "."){
        local section = Section[1]
        display as result " Section `section' ---------------"
        file write `myf' "# `section'"
        file write `myf' _n
        file write `myf' _n
      }
      if (Subsection[1] != "`subsection'") & (Subsection[1] != "") & (Subsection[1] != "."){
        local subsection = Subsection[1]
        display as result "  + Subsection `subsection' -------------"
        file write `myf' "## `subsection'"
        file write `myf' _n
        file write `myf' _n
      }
      //----------------------- IN CASE OF FIGURES -------------------------------
      if (regexm(lower(Figure[1]), "^y")){
        display as result "  + Figure `id' ---------------"
        file write `myf' `"::: {custom-style="center"}"' _n
        file write `myf' "![`caption'](`fig_dir'/`id'.png)" _n
        file write `myf' _n
        file write `myf' ":::" _n
      }
      else{
      //----------------------- IN CASE OF TABLES --------------------------------
        * look for section and mode
        display as result "  + Table `id' ---------------"
        file write `myf' "<<dd_do: nocommands>>" _n
        file write `myf' `"quietly use "`tab_dir'/`id'.dta", clear"' _n
        file write `myf' `" capture kable, space(90) cap("`caption'") out("temp.md")"'_n
        file write `myf' "<</dd_do>>"
        file write `myf' _n
        file write `myf' _n
        file write `myf' `"<<dd_include: "temp.md">>"' _n
      }
      if ("`footnote'" != ""){
        file write `myf' `"::: {custom-style="footnote"}"' _n
        file write `myf' "`footnote'" _n
        file write `myf' ":::" _n
        file write `myf' _n
        file write `myf' _n
      }
	}

	// The document must end with a portrait mode
	if ("`mode'" != "Portrait") {
		file write `myf' "\BeginPortrait" _n
	}

	file close `myf'
	display as result "Sucessfully created the dyntex file"
end
