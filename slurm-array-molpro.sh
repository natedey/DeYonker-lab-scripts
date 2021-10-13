#!/bin/bash
#SBATCH --ntasks=4
#SBATCH --time=72:00:00
#SBATCH --partition=computeq
#SBATCH --output=molpro_%A_%a.out
#SBATCH --mem-per-cpu=4GB

# Usage :
# sbatch --array=001-arg1%arg2 --export=name=arg3 ~/newbin/slurm-array-molpro.sh
# arg1 is number of energy points (or total points in the indexed array) to run 
# arg2 is number of jobs you want to run at a time (should be less than 25!)
# arg3 is the root name of the input files

# example - if you have 625 steps to run in directories named mgcch001 to mgcch625, and you
# want to do 10 jobs at a time, you would run
# sbatch --array=001-625%10 --export=name=mgcch ~/newbin/slurm-array-molpro.sh

#export PATH=$PATH:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin
export PATH=$PATH:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/home/ndyonker/src/mrcc/intel-30iter
export MOLPRO=/home/ndyonker/bin/molpro2018/bin
export TCGRSH=/usr/bin/ssh
module load intel

#name=mgcch
echo imported name is $name
CASE_NUM=`printf %03d $SLURM_ARRAY_TASK_ID`

mkdir /home/scratch/$USER/$SLURM_JOB_ID

cd $SLURM_SUBMIT_DIR/$name$CASE_NUM
if [ -f 1.out ] && [ -n "`tail -n 5 1.out | grep "Molpro calculation terminated"`" ]; then
    echo $name$CASE_NUM Molpro already completed
else
        echo Trunk directory is $SLURM_SUBMIT_DIR
        echo MPIRUN at `which mpirun`
        export TMPDIR=/home/scratch/$USER/$SLURM_JOB_ID/$CASE_NUM
        export outdir=$SLURM_SUBMIT_DIR/$name$CASE_NUM
        mkdir $TMPDIR
        echo tmp directory is $TMPDIR
        echo env is $ENVIRONMENT
        echo Running on host `hostname`
        echo "SLURM_JOBID: " $SLURM_JOB_ID
        echo "SLURM_ARRAY_TASK_ID: " $CASE_NUM 
        $MOLPRO/molpro -d $TMPDIR -n 4 1.inp 2>&1 | tee -a $SLURM_SUBMIT_DIR/$name$CASE_NUM/1.out
        rm -rf $TMPDIR
        echo $name$CASE_NUM newly completed
fi

