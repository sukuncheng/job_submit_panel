#!/bin/bash -l

#####################
# job-array example #
#####################

#SBATCH --account=nn2993k 
#SBATCH --job-name=example
#SBATCH --nodes=4             #NUM_NODES
#SBATCH --ntasks-per-node=2   # by default=128, for MPI 
#SBATCH --cpus-per-task=1     # set=1 for MPI 
#SBATCH --time=0-00:01:00
#SBATCH --qos=devel

for (( i=0; i<4; i++)); do
    srun -N1 -n2 -r $i --mpi=pmi2 hostname >>test_$SLURM_JOB_ID.txt &    
done
# echo $SLURM_ARRAY_TASK_ID
# echo $SLURM_JOB_ID
# echo $SLURM_NTASKS
# cd ${SLURM_SUBMIT_DIR}
wait
exit 0
