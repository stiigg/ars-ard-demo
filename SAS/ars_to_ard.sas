
/* SAS: ARS JSON -> ARD (AGE by ARM) */
/* Adjust the path below if needed */
filename arsfile "../ars.json";
libname ars json fileref=arsfile;

%let data_dir=../data;
%let adsl_csv=&data_dir./ADSL.csv;

/* Import ADSL CSV */
proc import datafile="&adsl_csv" out=ADSL dbms=csv replace; guessingrows=max; run;

/* Extract minimal fields from JSON (paths may vary with JSON engine version) */
proc sql noprint;
  /* Grab simple scalar values by name from parsed JSON tables */
  select value into :analysis_id trimmed from ars.alist where upcase(p1)='ANALYSIS_ID';
  select value into :dataset     trimmed from ars.alist where upcase(p1)='DATASET';
  select value into :pop_where   trimmed from ars.alist where upcase(p2)='WHERE';
  select value into :group_var   trimmed from ars.alist where upcase(p2)='VARIABLE' and upcase(p1)='GROUPING';
  select value into :var_name    trimmed from ars.alist where upcase(p2)='NAME' and upcase(p1)='VARIABLES';
quit;

/* Filter population */
data adsl_pop;
  set &dataset;
  if &pop_where; /* e.g., SAFFL == 'Y' */
run;

/* Compute stats */
proc means data=adsl_pop n mean std median p25 p75 min max nway;
  class &group_var;
  var &var_name;
  output out=_stats
    n=N mean=MEAN std=SD median=MEDIAN p25=P25 p75=P75 min=MIN max=MAX;
run;

/* Long-format ARD */
data ARD_DM_AGE(keep=analysis_id group1 group1_level variable stat_name stat
                      population method studyid sap_section inputs_ver);
  length analysis_id group1 variable stat_name $40 group1_level $200
         population method studyid sap_section inputs_ver $100;
  set _stats;
  array vals  N MEAN SD MEDIAN P25 P75 MIN MAX;
  array names[8] $32 _temporary_ ('N','mean','sd','median','p25','p75','min','max');

  do i=1 to dim(vals);
    analysis_id = "&analysis_id";
    group1      = "&group_var";
    group1_level= vvaluex("&group_var");
    variable    = "&var_name";
    stat_name   = names[i];
    stat        = vals[i];
    population  = "SAFETY";
    method      = "Descriptive statistics (PROC MEANS)";
    /* Optional traceability: */
    studyid     = "XYZ123"; sap_section="5.1.2"; inputs_ver="ADaM_2025-09-01";
    output;
  end;
run;

proc export data=ARD_DM_AGE outfile="../ARD_DM_AGE.csv" dbms=csv replace; run;
