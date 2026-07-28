#! /bin/bash

#SBATCH --job-name="spades1"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 24:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

date

module load spades

spades.py -t 20 \
    -1 run1_cleaned_reads_R1.fastq.gz -2 run1_cleaned_reads_R2.fastq.gz \
    -1 run2_cleaned_reads_R1.fastq.gz -2 run2_cleaned_reads_R2.fastq.gz \
    -1 run3_cleaned_reads_R1.fastq.gz -2 run3_cleaned_reads_R2.fastq.gz \
    -o sample_name_output \
    -k 55,77,93,105 --careful

date
