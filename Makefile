run:          ## R engine → out/
	ENGINE=r bash scripts/run.sh ars.json data/ADSL.csv out

run-sas:      ## SAS engine → out_sas/
	ENGINE=sas bash scripts/run.sh ars.json data/ADSL.csv out_sas

validate:     ## Validate ARS (no external deps)
	python3 scripts/validate_ars_min.py ars.json

validate-strict:  ## Local-only strict JSON Schema check
	python3 -m pip install --quiet jsonschema
	python3 scripts/validate_ars.py ars.json schema/ars.schema.json

diff:         ## Compare R vs SAS ARD
	python3 -m pip install --quiet pandas numpy
	python3 scripts/compare_ard.py out out_sas

.PHONY: run run-sas validate validate-strict diff
