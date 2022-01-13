#!/bin/bash

for fn in $*;
do
    cut -f 1,2,5 $fn | awk -v FNAME=$fn '{if ($3 == "0" || $3 == "318829" || $3 == "4530") print FNAME $0; }'
done