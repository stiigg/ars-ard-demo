/* Batch:
   sas -sysin SAS/ars_to_ard.sas -set ARS ars.json -set ADSL data/ADSL.csv -set OUT out_sas
*/
%include "SAS/macros/ars_macros.sas";
%let ARS  = %sysget(ARS);
%let ADSL = %sysget(ADSL);
%let OUT  = %sysget(OUT);

filename adslcsv "&ADSL";
proc import datafile=adslcsv dbms=csv out=work.adsl replace; guessingrows=max; run;

%let analysis_id = DM_AGE_SUMMARY;
%let filter      = SAFFL = "Y";
%let var         = AGE;
%let by          = ARM;

%ars_subset_pop(in=work.adsl, out=work.pop, filter=&filter);
%ars_summarize(in=work.pop, var=&var, by=&by, out=work.sum);
%ars_to_ard(in=work.sum, analysis_id=&analysis_id, var=&var, outcsv="&OUT./ARD_&analysis_id..csv");
