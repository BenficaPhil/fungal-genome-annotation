#! /bin/bash

#SBATCH --job-name="mafft"
#SBATCH --array=1-100
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 24:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

date

# Specify the path to the config file. This should contain odb IDs (e.g. odb_10007)
# Make the array range consistent with the number of samples being run
config=./config_samples.txt

# Extract the odb_id for the current $SLURM_ARRAY_TASK_ID
odb_id=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $2}' $config)

# Load MAFFT
module load mafft

# For example, mafft --auto odb_10007.fasta > NEXUS/odb_10007.fasta
# Output to NEXUS folder
mafft --auto ${odb_id}.fasta > NEXUS/${odb_id}.fasta

date