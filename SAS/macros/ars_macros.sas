%macro ars_subset_pop(in=, out=, filter=);
  data &out; set &in; if &filter; run;
%mend;

%macro ars_summarize(in=, var=, by=, out=);
  proc summary data=&in nway;
    class &by;
    var &var;
    output out=&out(drop=_type_ _freq_)
      n=N mean=MEAN std=SD median=MEDIAN q1=Q1 q3=Q3 min=MIN max=MAX;
  run;
%mend;

%macro ars_to_ard(in=, analysis_id=, var=, outcsv=);
  data _long;
    set &in;
    length ANALYSISID PARAMCD PARAM STAT $40;
    ANALYSISID="&analysis_id"; PARAMCD="&var"; PARAM="&var";
    array S[*] N MEAN SD MEDIAN Q1 Q3 MIN MAX;
    do i=1 to dim(S);
      STAT=vname(S[i]); VALUE=S[i]; output;
    end;
    drop i N MEAN SD MEDIAN Q1 Q3 MIN MAX;
  run;
  data _long; set _long; ENGINE="SAS"; ENGINE_VERSION="&sysvlong4"; RUN_DATETIME="%sysfunc(datetime(), E8601DT.)"; run;
  proc export data=_long outfile="&outcsv" dbms=csv replace; run;
%mend;
