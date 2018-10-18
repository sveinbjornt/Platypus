#!/usr/bin/python -u

import sys
import os

out_fn = '../../../args.txt'

try:
    os.remove(out_fn)
except:
    pass

with open(out_fn,'w') as f:
    for arg in sys.argv[1:]:
        f.write(arg + "\n")
        print(arg)

f.close()
