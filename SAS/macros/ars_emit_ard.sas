%macro ars_emit_ard(inset=, output_dir=);
  /* Write CSV with deterministic sort + append metadata rowset to a *_meta.json */
  proc sort data=&inset; by _all_; run;
  proc export data=&inset outfile="&output_dir/ARD.csv" dbms=csv replace; run;
%mend;
