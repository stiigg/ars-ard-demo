%macro ars_parse_json(spec_path=);
  /* Example using libname JSON; adapt to your structure */
  libname _ars json "&spec_path";
  /* Create WORK._ARS_SOURCES, WORK._ARS_POP, WORK._ARS_JOINS, WORK._ARS_ANALYSES */
  /* ... */
  libname _ars clear;
%mend;
