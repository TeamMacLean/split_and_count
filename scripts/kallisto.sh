#!/usr/bin/bash

source kallisto-0.46.2

idx=$1
threads=$2
boots=$3
fq1=$4
fq2=$5
out=$6

kallisto quant -i $idx -t $threads -b $boots -o $out $fq1 $fq2