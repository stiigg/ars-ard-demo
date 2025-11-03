import argparse

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--r", required=True)
    parser.add_argument("--py", required=True)
    parser.add_argument("--sas", required=True)
    parser.add_argument("--report", required=True)
    parser.parse_args()
    # TODO: implement parity comparison

if __name__ == "__main__":
    main()
