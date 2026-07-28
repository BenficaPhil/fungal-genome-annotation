#! /bin/bash
#SBATCH --job-name="blasbea1"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 48:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

date

INPUT_DIR=/project/entfun/PHILIP_FUNGI_PROJECT/library/BEA/funannotate/A04_25_OUTPUT/predict_results/

cp ${INPUT_DIR}/Beauveria_bassiana_ARSEF_1816.proteins.fa $TMPDIR
cp /project/entfun/PHILIP_FUNGI_PROJECT/ncbi_db/f* $TMPDIR
cd $TMPDIR

module load blast+
module load parallel

cat “beauveria”_“bea”.proteins.fa | \
parallel \
	--block 50k \
	--recstart '>' \
	--pipe blastp \
	-num_threads 20 \
	-num_alignments 5 \
	-num_descriptions 5 \
	-db $TMPDIR/fungi_ncbi.fasta \
	-query - > combined_results_A04_25_fungi_ncbi.txt

cp $TMPDIR/combined_results_A04_25_fungi_ncbi.txt ${INPUT_DIR}/temp

date