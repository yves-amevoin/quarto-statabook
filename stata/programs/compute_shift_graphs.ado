capture program drop compute_shift_graphs
// Compute the shift graphs and add the required ranges (and the units)
// ranges are saved as input in an excel file called shift_graphs_inputs.xlsx 
program compute_shift_graphs

  syntax varlist(max=1) [if], EVARiable(varlist max=1) EVALue(numlist integer max=1) BASEvalue(numlist integer max=1) name(string) IDvariable(varlist max=1) OUTputdir(string) SUFfix(string) CONFigfile(string) 
  marksample touse, novarlist
  display "`configfile'"

  //First load the ranges and units files
  capture confirm file "`configfile'"
  if (_rc){
    display as error "Config file `Configfile' not found"
    exit 3
  }
  
 
  preserve
    import excel using "`configfile'", firstrow clear
    keep if parameter == "`varlist'" | name == "`name'"
    quietly count
    if (r(N) != 1) {
      display as error "Not unique identifier or identifier not found (N = `r(N)')"
      exit 3
    }
    local unit = units[1]
    local lln = lln[1]
    local uln = uln[1]
    local lname = name[1]
  restore
  
   
  display "--- Shift graph for `lname'" // a title to your chart
  tempfile mydata
  
  preserve
    keep if `touse'
    keep `varlist' `evariable' `idvariable'
    save "`mydata'"
  restore

  local base: label (`evariable') `basevalue'
  local ag: label (`evariable') `evalue'
  
  preserve
    use "`mydata'", clear
    tempfile against
    keep if `evariable' == `evalue'
    rename `varlist' `varlist'`evalue'
    quietly sum `varlist'`evalue', detail
    //minimum and maximum on the yaxis
    *Maximum
    local maxy = r(max)
    local maxy = max(`uln', `maxy') + 0.01
    *Minimum
    local miny = r(min)
    local miny = min(`lln', `miny') - 0.01
    save "`against'"
    
   
    use "`mydata'", clear
    keep if `evariable' == `basevalue' // I suppose 0 is the baseline value
    
  
    // Minimum and maximum for the x axis
    quietly sum `varlist', detail
    //minimum and maximum on the xaxis
    local maxr = r(max)
    local maxr = max(`uln', `maxr', `maxy') + 0.02
    *Minimum
    local minr = r(min)
    local minr = min(`lln', `minr', `miny') - 0.02
    display "`minr' `maxr'"
    local maxr1 = `maxr' * 1.068
    
    merge 1:1 `idvariable' using "`against'"
    keep if _merge == 3
    local luln = string(`uln', "%9.1f")
    local llln = string(`lln', "%9.1f")
    quietly twoway ///
    (scatter `varlist'`evalue' `varlist' ///
    , sort mlcolor(black%68)  mfcolor(black%60) ///
    msize(2-pt)  msymbol(smcircle)  ///
    text(`uln' `maxr1' "ULN" "`luln' `unit'", place(n) size(2rs) color(black)) ///
    text(`lln' `maxr1' "LLN" "`llln' `unit'", place(n) size(2rs) color(black)) ///
    text(`maxr1' `lln' "LLN" "`llln' `unit'", place(ne) size(2rs) color(black)) ///
    text(`maxr1' `uln' "ULN" "`luln' `unit'", place(ne) size(2rs) color(black)) ) ||  ///
    (function y = x, range(`minr' `maxr1') lcolor(gray) lwidth(0.2)),  ///
     yline(`lln' `uln', lwidth(0.168) lcolor(gray) lpattern("dash")) ///
     xline(`lln' `uln', lwidth(0.168) lcolor(gray) lpattern("dash")) ///
     ytitle("`lname' at `ag' (`unit')") ytitle(, size(vsmall) color(black)) ///
     yla(, labsize(vsmall) nogrid glcolor()) ///
     xtitle("`lname' at `base' (`unit')") ///
     xtitle(, size(vsmall)) xlabel(, labsize(vsmall) ///
     tlcolor(black) nogrid) legend(off) graphregion(fcolor(white) ///
     lcolor(white)) plotregion(fcolor(white) ifcolor(white))
  restore
  
  capture graph save "`outputdir'/`varlist'_`evalue'_`suffix'"
  capture graph export "`outputdir'/`varlist'_`evalue'_`suffix'.png", as(png)
  capture graph save "`outputdir'/`varlist'_`evalue'_`suffix'", replace
  capture graph export "`outputdir'/`varlist'_`evalue'_`suffix'.png", as(png) replace
end
