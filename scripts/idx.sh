#!/usr/bin/bash

source kallisto-0.46.2



fasta=$1
idx=$2

kallisto index -i $idx $fasta