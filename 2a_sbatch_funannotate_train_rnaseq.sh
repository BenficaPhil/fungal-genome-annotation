#! /bin/bash

#SBATCH --job-name="BEAtrain"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 48:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

date

module load miniconda

source activate /project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15

export GENEMARK_PATH=/project/entfun/PHILIP_FUNGI_PROJECT/software/GeneMark-ES

# Run funannotate train by inputting cleaned fastq files from SRA RNA-seq data
funannotate train --cpus ${SLURM_NTASKS} \
	-i ARSEF8028_contigs_sorted.fasta -o BEA_train_output \
	--left SRR3269778_1_cleaned.fastq SRR3269779_1_cleaned.fastq SRR3269780_1_cleaned.fastq SRR15242230_1_cleaned.fastq \
	--right SRR3269778_2_cleaned.fastq SRR3269779_2_cleaned.fastq SRR3269780_2_cleaned.fastq SRR15242230_2_cleaned.fastq \
	--species "Beauveria bassiana" --strain "ARSEF 8028" \
	--jaccard_clip 

# Run funannotate predict on the same strain used for training. This will allow the pretrained data to later be used on other samples.
funannotate predict --cpus ${SLURM_NTASKS} --force \
	-i ARSEF8028_contigs_sorted.fasta -o BEA_train_output \
	--species "Beauveria bassiana" --strain "ARSEF 8028" --name bea

# This saves the pretrained data as a "species" which can be used on runs for the other samples.
funannotate species -s beauveria_bassiana_arsef_8028 \
	-a BEA_train_output/predict_results/beauveria_bassiana_arsef_8028.parameters.json

date