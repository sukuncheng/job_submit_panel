# 
#!/bin/bash
job_list=$(squeue -u chengsukun)
XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
while [[ $XPID -ge 1 ]]; do # set the maximum of simultaneous running jobs, don't have to be Ne
        scancel -u chengsukun
        sleep 20        
        job_list=$(squeue -u chengsukun)
        XPID=$(grep -o chengsuk <<<$job_list |wc -l)  # number of current running jobs
done     
echo "cleaned all submitted jobs"