#!/usr/bin/bash

source kraken-2.0.8

db=$1
threads=$2
output=$3
report=$4
fq1=$5
fq2=$6

kraken2 \
    --db $db \
    --threads $threads \
    --paired \
    --gzip-compressed \
    --report $report\
    --output $output \
    $fq1 $fq2