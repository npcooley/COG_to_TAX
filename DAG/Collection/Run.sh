#! /bin/bash

Rscript Run.R ${1} ${2}

# success and failure is controlled by the dag, if anything weird happens,
# just let the job get bonked
