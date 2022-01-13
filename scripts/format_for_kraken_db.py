#!/usr/bin/env python

from Bio import SeqIO
import sys

count = 1
with open(sys.argv[2]) as fh:

    for record in SeqIO.parse(fh, "fasta"):
        r = ">osicds{}|kraken:taxid|{}\n{}".format(count, sys.argv[1], record.seq)
        print(r)
        count = count + 1
