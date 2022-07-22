#!/bin/bash -l
#set -uex
#####################
# job-array example #
#####################
#SBATCH --array=1-3
#SBATCH --account=nn2993k 
#SBATCH --job-name=example
#SBATCH --nodes=4             
#SBATCH --ntasks-per-node=1  
#SBATCH --cpus-per-task=1    
#SBATCH --exclusive
#SBATCH --time=0-00:05:00
echo $SLURM_ARRAY_TASK_ID
echo $SLURM_JOB_ID
echo $SLURM_NTASKS
 srun --nodes 1 --ntasks-per-node=1 echo 'hello from node 1' > test1_${SLURM_ARRAY_TASK_ID}_${SLURM_JOB_ID}.txt &
 srun --nodes 2 --ntasks-per-node=2 echo 'hello from node 2' >> test2_${SLURM_ARRAY_TASK_ID}_${SLURM_JOB_ID}.txt &
 srun --nodes 3 --ntasks-per-node=3 echo 'hello from node 3' >> test3_${SLURM_ARRAY_TASK_ID}_${SLURM_JOB_ID}.txt &
cd ${SLURM_SUBMIT_DIR}
wait    #It makes sure that the batch job won't exit before all the simultaneous sruns are completed. 
exit 0

# we execute the job and time it
# time mpirun -np $SLURM_NTASKS ./my_binary.x > my_output
