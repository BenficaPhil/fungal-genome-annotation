#! /bin/bash

#SBATCH --job-name="trainbus"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 48:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

date

# Activate the funannotate conda environment
module load miniconda

source activate /project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15

# Path to GeneMark-ES
export GENEMARK_PATH=/project/entfun/PHILIP_FUNGI_PROJECT/software/GeneMark-ES

# Setup a BUSCO database for sordariomycetes
funannotate setup -b sordariomycetes

# Run funannotate predict with busco_seed_species and busco_db to train AUGUSTUS on BUSCO predictions
funannotate predict --cpus ${SLURM_NTASKS} --force \
	-i ARSEF8028_contigs_sorted.fasta -o ARSEF8028_OUTPUT \
	--species "Beauveria bassiana" --strain "ARSEF 8028" --name bea \
	--protein_evidence $FUNANNOTATE_DB/uniprot_sprot.fasta --transcript_evidence transcripts_BEA.fasta \
	--busco_seed_species fusarium_graminearum --busco_db sordariomycetes

date