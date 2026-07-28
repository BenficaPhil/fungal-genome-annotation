#! /bin/bash

#SBATCH --job-name="funpred"
#SBATCH --array=1-65
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 24:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

# Specify the path to the config file
config=./config_BEA_samples.txt

# Extract the sample name for the current $SLURM_ARRAY_TASK_ID
sample=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)

# Extract the species, e.g. Beauveria bassiana
species=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $3}' $config)

# Extract the strain name/identifier, e.g. ARSEF 1816
strain=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $4}' $config)

# Extract the locus tag, e.g. NWO35
locus_tag=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $5}' $config)

date

# Activate funannotate conda environment
module load miniconda

source activate /project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15

# Path to GeneMark-ES
export GENEMARK_PATH=/project/entfun/PHILIP_FUNGI_PROJECT/software/GeneMark-ES

# Run funannotate predict
funannotate predict --cpus 20 --force \
	-i ${sample}_contigs_sorted.fasta -o ${sample}_OUTPUT \
	--species "${species}" --strain "${strain}" --name ${locus_tag} \
	--protein_evidence $FUNANNOTATE_DB/uniprot_sprot.fasta --transcript_evidence transcripts_BEA.fasta \
	--augustus_species beauveria_bassiana_arsef_8028 --busco_db sordariomycetes

date