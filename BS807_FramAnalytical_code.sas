*BS807 Group Project
Last edited on: 12/07/2022
;

libname project "/home/u58215901/sasuser.v94/Group Project";

proc import out=project.fram /*n=11,627*/
	datafile = "/home/u58215901/sasuser.v94/Group Project/frmgham2.csv"
	dbms = CSV replace;
	getnames = yes;
run;

proc sort data=project.fram; by period; run;
proc freq data=project.fram;
	table CIGPDAY;
	by period;
run;

*Important variables:
	- RANDID: Unique identification number for each participant
	- PERIOD	
	- CIGPDAY: Number of cigarettes smoked each day
	- PREVCHD
	- Any CHD (as anychd)
	- Age
	- Educ: don't see how values are defined in codebook?
	- Sex
	- Diabetes
	- Chol (var name: totchol)
	- Hypertention (var names: sysBP and diaBP);

data transpose; *n=11,627;
	set project.fram;
run;

proc sort data=transpose; by randid; run; 

*MAIN EXPOSURE VAR;
proc transpose data=transpose out=CIGPDAY prefix=CIGPDAY;
	var CIGPDAY;
	by randid;
run;

*MAIN OUTCOME VAR;
proc transpose data=transpose out=anychd prefix=anychd;
	var anychd;
	by randid;
run;

proc transpose data=transpose out=prevchd prefix=prevchd;
	var prevchd;
	by randid;
run;

*OTHER COVARIATES;
proc transpose data=transpose out=diabetes prefix=diabetes;
	var diabetes;
	by randid;
run;

proc transpose data=transpose out=totchol prefix=totchol;
	var totchol;
	by randid;
run;

proc transpose data=transpose out=prevhyp prefix=prevhyp;
	var prevhyp;
	by randid;
run;

proc transpose data=transpose out=BMI prefix=BMI;
	var BMI;
	by randid;
run;

proc transpose data=transpose out=age prefix=age;
	var age;
	by randid;
run;

*ADMIN VARS;
proc transpose data=transpose out=period prefix=period;
	var period;
	by randid;
run;

proc transpose data=transpose out=death prefix=death;
	var death;
	by randid;
run;

data trans_fram;
	merge CIGPDAY anychd prevchd diabetes totchol prevhyp BMI age period death;
	by randid; *n=4434;

*MAIN EXPOSURE VAR;
	*Remove non-smokers at baseline (P1);
	if CIGPDAY1 = 0 then delete; *removes non-smokers, n=2181;
	
	*Remove anyone with missing information on smoking behavior;
	if CIGPDAY1 = . then delete; *n=2149; 
	if CIGPDAY2 = . then delete; *n=1883;
	
	*Categorizing smokers at P1;
	if 1 =< CIGPDAY1 =< 20 then smoke1 = 0; *Light smokers;
	else if 20 < CIGPDAY1 =< 90 then smoke1 = 1; *Heavy smokers;
	
	*Categorizing smokers at P2;
	if 0 =< CIGPDAY2 =< 20 then smoke2 = 0; *Light smokers;
	else if 20 < CIGPDAY2 =< 90 then smoke2 = 1; *Heavy smokers;

	*Creating 4 groups of smoking status;
	if smoke1 = 0 and smoke2 = 0 then smkstatus = 0;
	else if smoke1 = 0 and smoke2 = 1 then smkstatus = 1;
	else if smoke1 = 1 and smoke2 = 0 then smkstatus = 2;
	else if smoke1 = 1 and smoke2 = 1 then smkstatus = 3;

*MAIN OUTCOME VAR;
	*Deleting those who had PREVCHD at P1 or P2;
	if prevchd1 = 1 then delete;  
	if prevchd2 = 1 then delete; 
									*left with n=1743; 
	
	*Dichotomize anychd at P3;
	if anychd3 = 1 then chd = 1;
	else if anychd3 = 0 then chd = 0;

*OTHER COVARIATES;
	*Dichotomizing diabetes at baseline; 
	if diabetes1 = 0 then dm = 0; 
	else if diabetes1 = 1 then dm = 1;
	else if diabetes1 = . then dm = .;
	
	*Dichotomizing cholesterol at baseline; 
	if totchol1 < 200 then chol = 0; 
	else if totchol1 >= 200 then chol = 1;
	else if totchol1  = . then chol = .;
	
	*Dichotomizing HTN at baseline;
	if prevhyp1 = 0 then htn = 0; 
	else if prevhyp1 = 1 then htn = 1;
	else if prevhyp1 = . then htn = .;
	
	*Categorizing age at baseline;
	if 32 =< age1 =< 34 then age_cat = 0;
	else if 35 =< age1 =< 54 then age_cat = 1;
	else if 55 =< age1 =< 64 then age_cat = 2; 
	else if age1 >= 65 then age_cat = 3; 
	else if age1 = . then age_cat = .;
	
	*Collapsed age categories;
	if 32 =< age1 =< 54 then age_cat2 = 0;
	else if age1 >= 55 then age_cat2 = 1;  
	else if age1 = . then age_cat2 = .;
	
	*Categorizing BMI at baseline;
	if bmi1 < 18.5 then bmi_cat = 0;
	else if 18.5 =< bmi1 =< 24.9 then bmi_cat = 1;
	else if 25 =< bmi1 =< 29.9 then bmi_cat = 2;
	else if bmi1 >= 30 then bmi_cat = 3; 
	else if bmi1 = . then bmi_cat = .;
run;

proc format;
	value smkstatus
	0 = "Light-Light"
	1 = "Light-Heavy"
	2 = "Heavy-Light"
	3 = "Heavy-Heavy";
	value sex
	1 = "Men"
	2 = "Women";
	value educ 
	1 = "No HS"
	2 = "HS degree"
	3 = "Some college"
	4 = "College degree";
	value chd
	0 = "No CHD"
	1 = "CHD";
	value chol 
	0 = "Normal chol"
	1 = "Borderline or high chol";
	value htn
	0 = "Free of disease"
	1 = "Prevalent Hypertension";
	value age_cat
	0 = "32-54"
	1 = "35-54"
	2 = "55-64"
	3 = "65+";
	value age_cat_two
	0 = "32-54"
	1 = "55-70";
	value bmi_cat
	0 = "Underweight (<18.5)"
	1 = "Normal (18.5 – 24.9)"
	2 = "Overweight (25 – 29.9)"
	3 = "Obese (30+)";
	value chol
	0 = "Normal"
	1 = "Borderline high to high (>200)";
	value dm 
	0 = "Not a diabetic"
	1 = "Diabetic";
run;
 
*Creating a dataset just with variables that don't change overtime;
data demographics;
	set project.fram;
	keep randid sex educ;
run;

proc sort data=trans_fram; by randid; run;
proc sort data=demographics nodupkey; by randid; run;
data trans_demo;
	merge trans_fram (in=a) demographics;
	by randid;
	if a;
run;

data final;
	set trans_demo;
	keep randid smkstatus chd dm chol htn sex educ dm age_cat age_cat2 age1 bmi_cat bmi1;
proc print; run;

proc export data=final
    outfile="/home/u58215901/sasuser.v94/Group Project/data1.csv"
    dbms=csv
    replace;
run;
********************************Table 1********************************;
proc freq data=final;
	table smkstatus;
	format smkstatus smkstatus.;
run;

*Covariate row totals by exposure groups;
proc freq data=final;
	table (age_cat age_cat2 sex educ BMI_cat htn chol dm)*smkstatus / missing norow nocol;
	format smkstatus smkstatus. age_cat age_cat. age_cat2 age_cat_two. sex sex. educ educ. 
	bmi_cat bmi_cat. htn htn. chol chol. dm dm.;
run;

*Covariates by exposure groups;
proc freq data=final;
	table (age_cat age_cat2 sex educ BMI_cat htn chol dm)*smkstatus / missing norow nopercent;
	format smkstatus smkstatus. age_cat age_cat. age_cat2 age_cat_two. sex sex. educ educ. 
	bmi_cat bmi_cat. htn htn. chol chol. dm dm.;
run;

*Overall mean for age and BMI;
proc means data=final;
	var age1 bmi1;
run;

*Mean for age and BMI by smkstatus; 
proc sort data=final; by smkstatus; run;
proc means data=final;
	var age1 bmi1;
	by smkstatus;
	format smkstatus smkstatus.;
run;
