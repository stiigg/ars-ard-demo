import argparse
from .engine import run_ars
p = argparse.ArgumentParser()
p.add_argument("--spec", required=True)
p.add_argument("--in", dest="ind", required=True)
p.add_argument("--out", required=True)
p.add_argument("--seed", type=int, default=123)
args = p.parse_args()
run_ars(args.spec, args.ind, args.out, args.seed)
