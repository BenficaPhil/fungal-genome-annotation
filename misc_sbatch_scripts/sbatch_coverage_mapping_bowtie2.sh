#! /bin/bash

#SBATCH --job-name="bowtie21"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 24:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

date

INPUT_DIR=/project/entfun/cleaned_sequences

module load bowtie2

mkdir index

bowtie2-build A04_25_contigs.fasta index/A04_25_contigs

bowtie2 -p 20 -x index/A04_25_contigs \
	-1 ${INPUT_DIR}/run1_cleaned_reads_R1.fastq \
	-2 ${INPUT_DIR}/run1_cleaned_reads_R2.fastq \
	-1 ${INPUT_DIR}/run2_cleaned_reads_R1.fastq \
	-2 ${INPUT_DIR}/run2_cleaned_reads_R2.fastq \
	-1 ${INPUT_DIR}/run3_cleaned_reads_R1.fastq \
	-2 ${INPUT_DIR}/run3_cleaned_reads_R2.fastq \
	--al-conc--gz A04_25_map.fastq.gz -S A04_25_map.sam

module purge

module load bbtools

pileup.sh in=A04_25_map.sam covstats=A04_25_coverage.txt

date