#! /bin/bash

#SBATCH --job-name="BEAanno"
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

# These columns will have the species and strain names with underscores
# Extract the species, e.g. Beauveria_bassiana
species=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $6}' $config)

# Extract the strain name/identifier, e.g. ARSEF_1816
strain=$(awk -v ArrayTaskID=$SLURM_ARRAY_TASK_ID '$1==ArrayTaskID {print $7}' $config)

date

# Activate antiSMASH conda environment
module load miniconda

source activate /project/entfun/PHILIP_FUNGI_PROJECT/software/antiSMASH

# Run antiSMASH
antismash --taxon fungi \
	--output-dir ${sample}_OUTPUT/antiSMASH_results 
	--output-basename ${sample}_antiSMASH \
	--genefinding-tool none \
	${sample}_OUTPUT/predict_results/${species}_${strain}.gbk

# Deactivate conda environment
conda deactivate

# Activate funannotate conda environment
source activate /project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15

funannotate annotate --cpus 20 \
	-i ${sample}_OUTPUT \
	--sbt template_BEA_rehner.sbt \
	--species "${species}" --strain "${strain}" \
	--antismash ${sample}_OUTPUT/antiSMASH_results/${sample}_antiSMASH.gbk \
	--busco_db sordariomycetes

date