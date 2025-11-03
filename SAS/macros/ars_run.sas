%macro ars_run(spec_path=, input_dir=, output_dir=, tolerance=1e-8, log_level=INFO);

  %local _rc;
  %let _rc=0;

  %ars_parse_json(spec_path=&spec_path);

  %ars_load_sources(input_dir=&input_dir);

  %if %sysfunc(exist(WORK._ARS_POP)) %then %do;
    %ars_where_eval(inset=WORK.ANALYSIS, out=WORK.ANALYSIS_F, where_ds=WORK._ARS_POP);
  %end;
  %else %do;
    data WORK.ANALYSIS_F; set WORK.ANALYSIS; run;
  %end;

  %ars_summarize(inset=WORK.ANALYSIS_F, out=WORK.ARD, spec_ds=WORK._ARS_ANALYSES);

  %ars_emit_ard(inset=WORK.ARD, output_dir=&output_dir);

  %if &_rc ne 0 %then %do;
    %put ERROR: ARS_RUN failed with rc=&_rc.;
  %end;

%mend;
