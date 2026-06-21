#!/bin/bash

rm Siders*
rm *.h5

BMv4_setup configuration/model.json \
       --output setup.h5
BMv4_simulation configuration/$1 \
       setup.h5 \
       --output results.h5 \
       --backend omp --nthreads 16
BMv4_results configuration/results.json \
       results.h5 \
       -o mySim_output



