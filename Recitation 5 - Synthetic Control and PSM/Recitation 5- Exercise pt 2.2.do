******************************************
*                                        *
*                                        *
*               Exercise 2               *
*                                        *
*                                        *
******************************************

************ Exercise *************

// Perform placebo-date falsification, choosing 1989 as the treatment date and 1992 as the end of the sample to check if the model shows the same treatment effect you found above.

// Synthetic Control: thanks to Abadie, Diamond, and Hainmueller (2010)
set scheme gg_tableau

* Estimation 1: Texas model of black male prisoners (per capita) 
use https://github.com/scunning1975/mixtape/raw/master/texas.dta, clear
 

#delimit; 
synth   bmprison //1989 is treatment date
             bmprison(1988) bmprison(1987) bmprison(1986) bmprison(1985)    
            alcohol(1988) aidscapita(1988) aidscapita(1987) 
            income ur poverty black(1988) black(1987) black(1986) 
            perc1519(1987)
            ,       
        trunit(48) trperiod(1989) unitnames(state) 
        mspeperiod(1985(1)1989) resultsperiod(1985(1)1992)
        keep(/Users/brunokomel/Desktop/Recitation_6/data/synth_bmprate_ex22.dta) replace fig;
        mat list e(V_matrix);
        #delimit cr
        graph save Graph /Users/brunokomel/Desktop/Recitation_6/Figures/synth_tx_ex2.gph, replace
		


* Plot the gap in predicted error
use /Users/brunokomel/Desktop/Recitation_6/data/synth_bmprate_ex2.dta, clear
keep _Y_treated _Y_synthetic _time
drop if _time==.
rename _time year
rename _Y_treated  treat
rename _Y_synthetic counterfact
gen gap48=treat-counterfact
sort year
#delimit ; 
	twoway (line gap48 year,lp(solid)lw(vthin)lcolor(black)), yline(0, lpattern(shortdash) lcolor(black)) 
    xline(1989, lpattern(shortdash) lcolor(black)) xtitle("",si(medsmall)) xlabel(#10) 
    ytitle("Gap in black male prisoner prediction error", size(medsmall)) legend(off); 
    #delimit cr
    save /Users/brunokomel/Desktop/Recitation_6/data/synth_bmprate_48_ex2.dta, replace
	


* Inference 1 placebo test  
#delimit; 
set more off; 
use https://github.com/scunning1975/mixtape/raw/master/texas.dta, replace;
global statelist  1 2 4 5 6 8 9 10 11 12 13 15 16 17 18 20 21 22 23 24 25 26 27 28 29 30 31 32  33 34 35 36 37 38 39 40 41 42 45 46 47 48 49 51 53 55; 
foreach i of global statelist {;
synth   bmprison 
          bmprison(1988) bmprison(1987) bmprison(1986) bmprison(1985)    
          alcohol(1988) aidscapita(1988) aidscapita(1987) 
          income ur poverty black(1988) black(1987) black(1986) 
          perc1519(1987)
          ,       
        trunit(`i') trperiod(1989) unitnames(state) 
        mspeperiod(1985(1)1989) resultsperiod(1985(1)1992)
            keep(/Users/brunokomel/Desktop/Recitation_6/data/synth_bmprate_`i'_ex2.dta) replace; 
            matrix state`i' = e(RMSPE); /* check the V matrix*/ 
};
foreach i of global statelist {; 
matrix rownames state`i'=`i'; 
matlist state`i', names(rows); 
};

#delimit cr


 foreach i of global statelist {
    use /Users/brunokomel/Desktop/Recitation_6/data/synth_bmprate_`i'_ex2 ,clear
    keep _Y_treated _Y_synthetic _time
    drop if _time==.
    rename _time year
    rename _Y_treated  treat`i'
    rename _Y_synthetic counterfact`i'
    gen gap`i'=treat`i'-counterfact`i'
    sort year 
    save /Users/brunokomel/Desktop/Recitation_6/data/synth_gap_bmprate`i'_ex2, replace
    }
use /Users/brunokomel/Desktop/Recitation_6/data/synth_gap_bmprate48_ex2.dta, clear
sort year //sorting Texas only, for some reason
save /Users/brunokomel/Desktop/Recitation_6/data/placebo_bmprate48_ex2.dta, replace



// And below we merge all of them together
foreach i of global statelist {
        merge year using /Users/brunokomel/Desktop/Recitation_6/data/synth_gap_bmprate`i'_ex2 
        drop _merge 
        sort year 
    save /Users/brunokomel/Desktop/Recitation_6/data/placebo_bmprate_ex2.dta, replace 
    }
    

** Inference 2: Estimate the pre- and post-RMSPE and calculate the ratio of the
*  post-pre RMSPE   
set more off

foreach i of global statelist {

    use /Users/brunokomel/Desktop/Recitation_6/data/synth_gap_bmprate`i'_ex2, clear
    gen gap3=gap`i'*gap`i' // here we square the "gaps"
    egen postmean=mean(gap3) if year>1989
    egen premean=mean(gap3) if year<=1989
    gen rmspe=sqrt(premean) if year<=1989
    replace rmspe=sqrt(postmean) if year>1989
    gen ratio=rmspe/rmspe[_n-1] if 1990
    gen rmspe_post=sqrt(postmean) if year>1989
    gen rmspe_pre=rmspe[_n-1] if 1990
    mkmat rmspe_pre rmspe_post ratio if 1990, matrix (state`i')
}	
	
	
* show post/pre-expansion RMSPE ratio for all states, generate histogram
    foreach i of global statelist {
        matrix rownames state`i'=`i'
        matlist state`i', names(rows)
                                    }
									
									
#delimit ;
matrix state=state1\state2\state4\state5\state6\state8\state9\state10\state11\state12\state13\state15\state16\state17\state18\state20\state21\state22\state23\state24\state25\state26\state27\state28\state29\state30\state31\state32\state33\state34\state35\state36\state37\state38\state39\state40\state41\state42\state45\state46\state47\state48\state49\state51\state53\state55; 
#delimit cr


* ssc install mat2txt
    mat2txt, matrix(state) saving(/Users/brunokomel/Desktop/Recitation_6/inference/rmspe_bmprate_ex2.txt) replace
    insheet using /Users/brunokomel/Desktop/Recitation_6/inference/rmspe_bmprate_ex2.txt, clear
    ren v1 state
    drop v5
    gsort -ratio
    gen rank=_n
    gen p=rank/46
    export excel using /Users/brunokomel/Desktop/Recitation_6/inference/rmspe_bmprate_ex2, firstrow(variables) replace
    import excel /Users/brunokomel/Desktop/Recitation_6/inference/rmspe_bmprate_ex2.xls, sheet("Sheet1") firstrow clear
	drop if missing(rmspe_pre) | missing(rmspe_post) 
	drop if ratio == 1 // This is my attempt at correcting some error from the author
    histogram ratio, bin(20) frequency fcolor(navy) lcolor(black) ylabel(0(2)10) xtitle("Post/pre RMSPE ratio") xlabel(15(1)20)
* Show the post/pre RMSPE ratio for all states, generate the histogram.
    list rank p if state==48
	
	
* Inference 3: all the placeboes on the same picture
use /Users/brunokomel/Desktop/Recitation_6/data/placebo_bmprate.dta, replace
* Picture of the full sample, including outlier RSMPE
#delimit;   
twoway 
(line gap1 year ,lp(solid)lw(vthin)) 
(line gap2 year ,lp(solid)lw(vthin)) 
(line gap4 year ,lp(solid)lw(vthin)) 
(line gap5 year ,lp(solid)lw(vthin))
(line gap6 year ,lp(solid)lw(vthin)) 
(line gap8 year ,lp(solid)lw(vthin)) 
(line gap9 year ,lp(solid)lw(vthin)) 
(line gap10 year ,lp(solid)lw(vthin)) 
(line gap11 year ,lp(solid)lw(vthin)) 
(line gap12 year ,lp(solid)lw(vthin)) 
(line gap13 year ,lp(solid)lw(vthin)) 
(line gap15 year ,lp(solid)lw(vthin)) 
(line gap16 year ,lp(solid)lw(vthin)) 
(line gap17 year ,lp(solid)lw(vthin))
(line gap18 year ,lp(solid)lw(vthin)) 
(line gap20 year ,lp(solid)lw(vthin)) 
(line gap21 year ,lp(solid)lw(vthin)) 
(line gap22 year ,lp(solid)lw(vthin)) 
(line gap23 year ,lp(solid)lw(vthin)) 
(line gap24 year ,lp(solid)lw(vthin)) 
(line gap25 year ,lp(solid)lw(vthin)) 
(line gap26 year ,lp(solid)lw(vthin))
(line gap27 year ,lp(solid)lw(vthin))
(line gap28 year ,lp(solid)lw(vthin)) 
(line gap29 year ,lp(solid)lw(vthin)) 
(line gap30 year ,lp(solid)lw(vthin)) 
(line gap31 year ,lp(solid)lw(vthin)) 
(line gap32 year ,lp(solid)lw(vthin)) 
(line gap33 year ,lp(solid)lw(vthin)) 
(line gap34 year ,lp(solid)lw(vthin))
(line gap35 year ,lp(solid)lw(vthin))
(line gap36 year ,lp(solid)lw(vthin))
(line gap37 year ,lp(solid)lw(vthin)) 
(line gap38 year ,lp(solid)lw(vthin)) 
(line gap39 year ,lp(solid)lw(vthin))
(line gap40 year ,lp(solid)lw(vthin)) 
(line gap41 year ,lp(solid)lw(vthin)) 
(line gap42 year ,lp(solid)lw(vthin)) 
(line gap45 year ,lp(solid)lw(vthin)) 
(line gap46 year ,lp(solid)lw(vthin)) 
(line gap47 year ,lp(solid)lw(vthin))
(line gap49 year ,lp(solid)lw(vthin)) 
(line gap51 year ,lp(solid)lw(vthin)) 
(line gap53 year ,lp(solid)lw(vthin)) 
(line gap55 year ,lp(solid)lw(vthin)) 
(line gap48 year ,lp(solid)lw(thick)lcolor(black)), /*treatment unit, Texas*/
yline(0, lpattern(shortdash) lcolor(black)) xline(1989, lpattern(shortdash) lcolor(black))
xtitle("",si(small)) xlabel(#10) ytitle("Gap in black male prisoners prediction error", size(small))
    legend(off);
#delimit cr



