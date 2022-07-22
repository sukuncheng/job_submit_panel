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
>${JOB_SETUP_DIR}/calc_result.md
echo "              type  NumberofObs.  [for.inn.]  [an.inn.]   for.inn.   an.inn.  for.spread    an.spread" > calc_result.md

# ENSPATH=/cluster/work/users/chengsukun/simulations/test_windcohesion_2020-01-07_7days_x_16cycles_memsize40
ENSPATH=/cluster/work/users/chengsukun/simulations/test_windcohesion_2019-10-15_7days_x_12cycles_memsize40
#
for (( k=1; k<=12;   k++ )); do
    path=${ENSPATH}/date${k}/filter
    string=$( tail -3 ${path}/calc.out|head -1 )
    echo "$string" >> ${JOB_SETUP_DIR}/calc_result.md
done
