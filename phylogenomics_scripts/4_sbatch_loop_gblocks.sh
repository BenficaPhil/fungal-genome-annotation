#! /bin/bash

#SBATCH --job-name="gblocks"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 24:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

date

# Run this script inside the NEXUS folder after MAFFT alignment.
ls *.fasta > alignments.list

grep -c ">" *.fasta > seq_number.list

sed 's/[^:]*://' seq_number.list | awk '{print int(($1 / 2) + 1 + ($1 % 2 != 0 ? 0.5 : 0))}' > values.list

# Convert lists to arrays for matching fasta filenames and values (number of sequences + 1).
readarray -t alignedList < alignments.list
readarray -t valueList < values.list

# Load conda environment with Gblocks installation
module load miniconda

source activate /project/entfun/PHILIP_FUNGI_PROJECT/software/Gblocks

# Run loop to process all alignments, using the value in the list in -b2
for i in "${!alignedList[@]}";
	do Gblocks "${alignedList[i]}" -t=c -e=.gb -b2="${valueList[i]}" -b4=5 -b5=h;
done

# Move results to new folder
mkdir Gblocks_OUTPUT

mv *.gb Gblocks_OUTPUT

cd Gblocks_OUTPUT

# Make new folder to run IQTree
mkdir IQTree

# Remove the .gb extension
for file in *.fasta.gb;
	do sed 's/ //g' $file > IQTree/"${file%.gb}"; 
done

cd partitions

python count_alignment_length.py

date
