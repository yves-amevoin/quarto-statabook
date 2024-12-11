 
capture program drop knit
program knit
	version 15
	tempfile pandoc_execution
	tempvar myf // file for pandoc execution output
	syntax using/ [, saving(string) replace default(string) reference(string) first(string) toc number_sec]
	// Checks if the input file exists
	confirm file "`using'"
	local input_file  "`using'"
	local output_instructions local output_file  "`saving'"
	// Confirm replacement before proceeding
	if("`replace'" == ""){
		if("`saving'" == ""){
	// The output file is missing, will create the same with a docx expression
		local output_file =  regexr("`using'", "[^.]+$", "docx")
		}
		else{
			check_exists "`saving'"
			//the file does not exist and it is created the first time
			`output_instructions'
		}
	}
	else{
		`output_instructions'
	}
	if ("`default'" == ""){
		local default_file = regexr("`using'", "[^/]+$", "default.yaml")
		local default_folder = regexr("`using'", "/[^/]+$", "")
		create_default_file "`default_file'" "`reference'" "`first'" "`using'" "`output_file'"
		display as text "Empty default file, will specify one by default"
		display as text "Modify the `default' file if necessary"
	}

	else{
		confirm file "`default'"
		local default_file  "`default'"
	}

	//changing the default file to ensure brackets are used
	local default_file  `""`default_file'""'
	local reference_doc  `""`reference'""'
	// Pandoc execution with default configurations, add by default the 
	// table-of-contents and the number-sections.
	if ("`toc'" == ""){
		local toc --table-of-contents
	}
	if ("`number_sec'" == ""){
		local number_sec --number-sections
	}	
	local pandoc_exec !pandoc --defaults=`default_file' `number_sec' --reference-doc=`reference_doc' `toc' 1> `pandoc_execution' 2>&1
	`pandoc_exec'
	
	*reading the file to tell if everything is fine
	file open `myf' using "`pandoc_execution'", read
	file read `myf' line
	if (r(eof) != 0){
	  display as result "Successfully create the microsoft word document"
	}
	
	while r(eof) == 0{
	  display as error "`line'"
		file read `myf' line	  
	}
	
end
/* CHECKS IF A FILE EXISTS AND RETURN AN IF NOT*/
capture program drop check_exists
program check_exists
	args targetfile
		//Ensure we can replace original output file with new one
	capture confirm new file "`targetfile'"
	if(_rc){
		display as error "-- use the replace option --"
		confirm new file "`targetfile'"
	}
end
