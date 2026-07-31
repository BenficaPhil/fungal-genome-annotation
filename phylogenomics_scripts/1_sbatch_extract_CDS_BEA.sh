#! /bin/bash

#SBATCH --job-name="BEAexCDS"
#SBATCH -p ceres
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 48:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

date

module load miniconda

source activate /project/entfun/PHILIP_FUNGI_PROJECT/software/phyluce

# Extract CDS - default identity
phyluce_probe_run_multiple_lastzs_sqlite \
    --db extract_CDS_BEA.sqlite \
    --output extract_CDS_BEA_lastz \
    --scaffoldlist ARSEF10882 ARSEF1098 ARSEF1456 ARSEF1816 ARSEF2075 ARSEF2571 ARSEF2685 ARSEF340 ARSEF3405 ARSEF3456 ARSEF353 ARSEF3819 ARSEF4377 ARSEF4598 ARSEF4850 ARSEF5438 ARSEF5446 ARSEF5492 ARSEF5641 ARSEF566 ARSEF5718 ARSEF5768 ARSEF617 ARSEF6234 ARSEF6723 ARSEF7256 ARSEF7259 ARSEF7270 ARSEF7273 ARSEF9201 SAR11_511 SAR11_512 SAR11_513 SAR11_514 SAR11_520 SAR11_526 SAR11_532 SAR11_539 SAR11_546 SAR11_551 SAR11_574 SAR11_580 SAR11_589 SAR11_591 SAR11_596 SAR11_601 SAR11_604 SAR11_610 SAR11_615 SAR11_616 SAR11_617 SAR11_621 SAR12_653 SAR12_658 SAR12_661 SAR12_665 SAR12_666 SAR12_671 SAR13_12  SAR13_30  SAR13_36  SAR14_726 SAR17_01  SAR17_02 \
    --genome-base-path BEA_CDS_transcripts \
    --probefile 502_odbhyp_CDS_ARSEF8028.fasta \
    --cores 20

phyluce_probe_slice_sequence_from_genomes \
    --lastz extract_CDS_BEA_lastz \
    --conf genomes_BEA1.conf \
    --flank 0 \
    --name-pattern "502_odbhyp_CDS_ARSEF8028.fasta_v_{}.lastz.clean" \
    --output extract_output

date