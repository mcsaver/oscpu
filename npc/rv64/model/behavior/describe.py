#!/usr/bin/env python3
"""Export ordered block behaviors, types, read/write sets and RTL source tags."""
import argparse
import json
from pathlib import Path
import sys
sys.dont_write_bytecode=True
from counter import counter
from lsu_queue import request_queue
from lsu_terminal import terminal

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out",type=Path)
    parser.add_argument("--model",choices=("counter","lsu-queue","lsu-terminal"),default="counter")
    args=parser.parse_args()
    model={"counter":counter,"lsu-queue":request_queue,"lsu-terminal":terminal}[args.model]()
    program=model.program()
    if hasattr(model,"instances"):program["instances"]=model.instances
    if hasattr(model,"materialize"):program["gpu_materialized_boundaries"]=sorted(model.materialize)
    text=json.dumps(program,indent=2)+"\n"
    if args.out:
        args.out.parent.mkdir(parents=True,exist_ok=True)
        args.out.write_text(text)
    else:print(text,end="")
if __name__=="__main__":main()
