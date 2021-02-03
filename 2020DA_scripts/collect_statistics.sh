#!/bin/bash
## purpose
# extract statistics from weekly assimilation results  date?/filter/calc.out
set -eux
err_report() {
    echo "Error on line $1"
}
trap 'err_report $LINENO' ERR

#
JOB_SETUP_DIR=$(cd `dirname $0`;pwd)
>${JOB_SETUP_DIR}/result.md
echo "              type  NumberofObs.  [for.inn.]  [an.inn.]   for.inn.   an.inn.  for.spread    an.spread" > result.md

ENSPATH=/cluster/work/users/chengsukun/src/IO_nextsim/run_2019-10-15_Ne30_T12_D7/I1_L600_R2_K2
#
for (( k=1; k<=8;   k++ )); do
    path=${ENSPATH}/date${k}/filter
    string=$( tail -3 ${path}/calc.out|head -1 )
    echo "$string" >> ${JOB_SETUP_DIR}/result.md
done
