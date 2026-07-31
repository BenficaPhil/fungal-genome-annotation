#! /bin/bash

#SBATCH --job-name="IQtree"
#SBATCH --array=1-481
#SBATCH -A your_account_name
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 48:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o "iqtree_gene_tree.%A.%a.stdout"

date

# Need to module use older modules because of Ceres update
module use /software/7/modulefiles

module load iq_tree

## Bash variables
fasta_file=$(sed -n "$SLURM_ARRAY_TASK_ID"p gene_tree_array)

partition_file=partitions/$(echo "$fasta_file" | sed "s/.fasta/_parts.txt/g")

output_prefix=$(echo "$fasta_file" | sed "s/.fasta//g")

## IQ-TREE command
iqtree -nt AUTO -s $fasta_file -spp $partition_file -m TESTMERGE -bb 1000 -pre $output_prefix

date