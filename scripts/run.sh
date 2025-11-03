#!/usr/bin/env bash
set -euo pipefail
ENGINE="${ENGINE:-r}"
ARS="${1:-ars.json}"
ADSL="${2:-data/ADSL.csv}"
OUT="${3:-out}"

case "$ENGINE" in
  r)      Rscript R/ars_to_ard.R --ars "$ARS" --adsl "$ADSL" --out "$OUT" ;;
  sas)    sas -sysin SAS/ars_to_ard.sas -set ARS "$ARS" -set ADSL "$ADSL" -set OUT "$OUT" ;;
  python) python3 python/ars_to_ard.py --ars "$ARS" --adsl "$ADSL" --out "$OUT" ;;
  *) echo "Unknown ENGINE=$ENGINE"; exit 2 ;;
esac
