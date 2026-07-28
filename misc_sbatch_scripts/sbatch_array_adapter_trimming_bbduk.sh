#! /bin/bash

#SBATCH --job-name="bbduk"
#SBATCH --array=1-195
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 24:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

# Specify the path to the config file
config=./config_BEA_reads.txt

# Extract the reads filename for the current $SLURM_ARRAY_TASK_ID from a column with filenames
reads=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)

date

module load bbtools

# Adapter trimming with BBDuk
bbduk.sh -Xmx1g \
    in1=${reads} in2=${reads} \
    out1=cleaned_${reads} out2=cleaned_${reads} \
    ref=adapters.fa ktrim=r k=23 mink=11 hdist=1 tpe tbo

date