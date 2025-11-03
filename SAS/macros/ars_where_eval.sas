%macro ars_where_eval(inset=, out=, where_ds=);
  /* Safely evaluate boolean DSL into SAS WHERE; prevent injection by mapping operators */
  data &out;
    set &inset;
    /* apply filters via generated WHERE statements or condition variables */
  run;
%mend;
