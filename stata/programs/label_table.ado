/*
import an excel table and add label to that table. The label_name is
the name of the first column, the table_name is the value_name is the name
of the second column, assuming your table has two columns only.

  - label_file: the file to use to label the tables
  - table_id: The id of the table in the label_file
  - label_name: the label of the first head of the table
  - tab_file: the final name of the table when saving
  - value_name: "name of the value column
*/

capture program drop label_table
program label_table
    version 15
	syntax, tab_file(string) label_file(string) tab_id(string) [label_name(string) value_name(string)] 
	import excel using "`label_file'", sheet("`tab_id'") firstrow clear
	capture tostring id, replace
	replace label = trim(label)
	tempfile label_data
	capture save "`label_data'"
	use "`tab_file'", clear
	merge 1:1 id using "`label_data'", force
	sort order
	keep  label value 
	order label value

//adding labels to files
  if("`label_name'" != ""){
	note label: `label_name'
  }
  
  if("`value_name'" != ""){
    note value: `value_name'
  }
	
	capture save "`tab_file'", replace 
end 
