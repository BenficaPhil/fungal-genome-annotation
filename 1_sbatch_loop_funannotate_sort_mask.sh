#! /bin/bash

#SBATCH --job-name="funsort"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -t 24:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

date

module load miniconda

source activate /project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15

export GENEMARK_PATH=/project/entfun/PHILIP_FUNGI_PROJECT/software/GeneMark-ES

readarray -t sampleList < samples.list

for i in "${!sampleList[@]}";
        do funannotate sort -i "${sampleList[i]}"_contigs.fasta -o "${sampleList[i]}"_contigs_sorted.fasta -b NODE --minlen 200
done

for i in "${!sampleList[@]}";
        do funannotate mask -i "${sampleList[i]}"_contigs_sorted.fasta -o "${sampleList[i]}"_contigs_masked.fasta -b NODE --minlen 200
done

date