#!/usr/bin/bash

source krakentools-1.2

kout=$1
kreport=$2
fq1=$3
fq2=$4
taxid=$5
out1=$6
out2=$7

extract_kraken_reads.py \
    -k $kout \
    -r $kreport \
    -s1 $fq1 -s2 $fq2 \
    -t $taxid \
    -o $out1 -o2 $out2 \
    --fastq-output --include-children