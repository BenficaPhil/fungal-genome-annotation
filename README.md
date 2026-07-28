# Fungal genome assembly and annotation at USDA-ARS
2023 workflow used for genome assembly and annotation, primarily featuring Funannotate v1.8.15. I worked with Dr. Stephen Rehner and Dr. Jonathan Shao to submit a dataset of annotated _Beauveria bassiana_ (and related species) genomes to NCBI GenBank.

## Previous publications
Parts of this workflow using an older Funannotate version (Funannotate v1.5.3) were used for the following publications.

Rehner SA, Gazis R, Doyle VP, Vieira WAS, Campos PM, Shao J. 2023. Genome Resources for the _Colletotrichum gloeosporioides_ Species Complex: 13 Tree Endophytes from the Neotropics and Paleotropics. Microbiol Resour Announc 12:e01040-22. https://doi.org/10.1128/mra.01040-22

Msanne J, Shao J, Ashby R, Campos P, Liu Y, Solaiman D. 2023. Draft Genome Sequence of the Sophorolipid-Producing Yeast _Pseudohyphozyma bogoriensis_ ATCC 18809. Microbiol Resour Announc 12:e00566-22. https://doi.org/10.1128/mra.00566-22

## Navigating the repository
Below I will show steps on how the workflow progresses and examples of individual commands.

See the directory funannotate_sbatch_scripts for examples of sbatches with more efficient setups such as Slurm arrays for parallel processing or loops to iterate through multiple samples.

## Linux environment and HPC usage
The workflow was performed using Linux command line and the USDA-ARS SCINet high performance computing (HPC) clusters. Therefore, you will see commands such as salloc or module load to access SCINet resources, or sbatch scripts for submitting jobs in the Slurm scheduler.

## Adapter trimming
Example of adapter trimming on paired-end reads:
```
salloc

module load bbtools

bbduk.sh -Xmx1g \
    in1=reads_R1.fastq.gz in2=reads_R2.fastq.gz \
    out1=cleaned_reads_R1.fastq.gz out2=cleaned_reads_R2.fastq.gz \
    ref=adapters.fa ktrim=r k=23 mink=11 hdist=1 tpe tbo
```

## Genome Assembly with SPAdes
Example of assembly on trimmed paired-end reads (inputting multiple sequencing runs):
```
module load spades

spades.py -t 20 \
    -1 run1_cleaned_reads_R1.fastq.gz -2 run1_cleaned_reads_R2.fastq.gz \
    -1 run2_cleaned_reads_R1.fastq.gz -2 run2_cleaned_reads_R2.fastq.gz \
    -1 run3_cleaned_reads_R1.fastq.gz -2 run3_cleaned_reads_R2.fastq.gz \
    -o sample_name_output \
    -k 55,77,93,105 --careful
```

## Installing Funannotate via Conda
At the time, Funannotate version v1.8.15 was new, so a few extra steps were recorded to make a fresh install on SCINet.

### Install Mambaforge for smoother conda install
```
cd /project/entfun/PHILIP_FUNGI_PROJECT/software

curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh"

bash Mambaforge-Linux-x86_64.sh
```

### Create conda environment in a SCINet Ceres project directory
```
module load miniconda

cd mambaforge/bin

./mamba create --prefix /project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15 funannotate
```

### Manually upgrade from 1.8.13 to 1.8.15
```
python -m pip install git+https://github.com/nextgenusfs/funannotate.git --upgrade --force --no-deps
```

### Activate conda environment
```
source activate /project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15
```

### Setup the Funannotate database
```
cd /project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15

mkdir funannotate_db

echo "export FUNANNOTATE_DB=/project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15/funannotate_db" > /project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15/etc/conda/activate.d/funannotate.sh

funannotate setup -i all
```

## GeneMark installation
For licensing reasons, GeneMark will not run unless it is manually installed. The GeneMark-ES software can be downloaded from here: http://topaz.gatech.edu/GeneMark/license_download.cgi

```
export GENEMARK_PATH=/project/entfun/PHILIP_FUNGI_PROJECT/software/GeneMark-ES
```

As the step 3 funannotate post-installation message mentions, the top line (shebang) of the perl scripts needs to be modified.

To automate this, a loop with a Linux sed command (search and replace) can be used. Recommended to backup these scripts just in case!

```
cd /project/entfun/PHILIP_FUNGI_PROJECT/software/GeneMark-ES

for i in *.pl; do sed -i 's/perl/env perl/' "$i"; done
```

## Running Funannotate: sort and mask
Filter small sequences and rename fasta headers.

Funannotate sort can be used to rename headers. A header prefix is set by -b. E.g. -b NODE provides a simple header for each sequence: NODE_1, NODE_2, and so on. Errors may result in later steps if the headers are not simplified.

Setting –minlen 200 is to remove sequences below 200 bp to meet the NCBI requirements.
```
funannotate sort -i contigs.fasta -o contigs_sorted.fasta -b NODE --minlen 200
```

Repetitive elements can be soft-masked from a genome assembly to help direct the ab-initio gene predictors.

The funannotate author recommends running masking for the program to be optimized, however, it is possible to skip this step if there are concerns the repeats regions may have some importance.
```
funannotate mask -i contigs_sorted.fasta -o contigs_masked.fasta
```

## Different options in training Funannotate
After various testing, we’ve found there are two different ways to proceed with training gene models in Funannotate.

The recommended “gold standard” is to utilize RNA-seq data to run funannotate train. However, there is a 2nd method that does not require RNA-seq data and skips funannotate train, which can provide results that are equally as good as the RNA-seq method (at least, where our genomes were concerned). This is an option to consider if high quality RNA-seq data is not available in the SRA and/or it is too costly to obtain the data.

We will demonstrate how both methods work:

## 1. RNA-seq method
### Choose best assembly to run training on
We had many genomes on hand, and chose one that was considered the best assembly to be the first genome that gets trained. This was _Beauveria bassiana_ ARSEF 8028.

### Download fastq RNA-seq data from the Sequence Read Archive (SRA)
We found a publication that deposited RNA-seq data (Illumina HiSeq 2000) for the same species/strain ARSEF 8028 in different growth conditions: https://bmcgenomics.biomedcentral.com/articles/10.1186/s12864-016-3339-1

* SRR3269778 (RNA reads mycelium)
* SRR3269779 (RNA reads “fruiting bodies”)
* SRR3269780 (RNA reads infected mosquitoes)

Searching these on NCBI’s SRA, we can see these are large datasets which hypothetically should provide a large amount of data for the training: https://www.ncbi.nlm.nih.gov/sra

The 1st replicate for each growth condition was used.

To provide some additional data for the training, we also added data from a different ARSEF strain. We will be annotating different strains and sometimes different _Beauveria_ species.

GSM5470881: WT-rep3; Beauveria bassiana ARSEF 2860; RNA-Seq (BGISEQ-500)
* SRR15242230

Performing the below steps will give you FASTQ files required for the training. Repeat the prefetch and fastq-dump commands for each SRA dataset.
```
cd /project/entfun/PHILIP_FUNGI_PROJECT/library/BEA/funannotate

mkdir -p train_funannotate/sra

cd train_funannotate/sra

module load sratoolkit

prefetch SRR[insert ID here]

fastq-dump --split-files SRR[insert ID here]
```

### Modify headers 
Before running training, the headers must be modified for compatibility with Trinity. Default headers from SRA will typically lead to errors.

Default headers look like this:
@SRR3269778.1 1 length=90

+SRR3269778.1 1 length=90

Our goal is to modify them to look like this:

@SRR3269778.1/1

+SRR3269778.1/1

Sed commands, or the Linux version of Search and Replace, are useful for manipulating fasta/q headers. I’ve combined two sed expressions into one command by using -e twice. The first expression removes ” length=90” (the actual expression has a wildcard * so this command works on other lengths too). The second expression locates the SRR ID and the number connected by the period, retains that info, and adds a /1 (for the forward reads) or /2 (for the reverse reads).

The commands are repeated, adjusting the command for SRR ID and forward or reverse read.

```
sed -e 's/ length=.*$//' -e 's/\(SRR3269778.[0-9]\+\) [0-9]\+/\1\/1/' SRR3269778_1.fastq > SRR3269778_1_cleaned.fastq

sed -e 's/ length=.*$//' -e 's/\(SRR3269778.[0-9]\+\) [0-9]\+/\1\/2/' SRR3269778_2.fastq > SRR3269778_2_cleaned.fastq

sed -e 's/ length=.*$//' -e 's/\(SRR3269779.[0-9]\+\) [0-9]\+/\1\/1/' SRR3269779_1.fastq > SRR3269779_1_cleaned.fastq

sed -e 's/ length=.*$//' -e 's/\(SRR3269779.[0-9]\+\) [0-9]\+/\1\/2/' SRR3269779_2.fastq > SRR3269779_2_cleaned.fastq

sed -e 's/ length=.*$//' -e 's/\(SRR3269780.[0-9]\+\) [0-9]\+/\1\/1/' SRR3269780_1.fastq > SRR3269780_1_cleaned.fastq

sed -e 's/ length=.*$//' -e 's/\(SRR3269780.[0-9]\+\) [0-9]\+/\1\/2/' SRR3269780_2.fastq > SRR3269780_2_cleaned.fastq

sed -e 's/ length=.*$//' -e 's/\(SRR15242230.[0-9]\+\) [0-9]\+/\1\/1/' SRR15242230_1.fastq > SRR15242230_1_cleaned.fastq

sed -e 's/ length=.*$//' -e 's/\(SRR15242230.[0-9]\+\) [0-9]\+/\1\/2/' SRR15242230_2.fastq > SRR15242230_2_cleaned.fastq
```

Move the cleaned.fastq files to the train_funannotate directory.

### Funannotate train
A full version of the sbatch script used for these next steps is in: 
funannotate_sbatch_scripts/2a_sbatch_funannotate_train_rnaseq.sh

```
cd /project/entfun/PHILIP_FUNGI_PROJECT/library/BEA/funannotate/train_funannotate
```

* First, set the input (sorted or masked fasta depending on preference).
* –left and –right accept the RNA-seq fastq files. Multiple file names can be inputted.
* –jaccard-clip is a recommended setting for fungi.
* –species and –strain will be used to name the training set. Use quotation marks if there are spaces in your names. In this example, Beauveria bassiana ARSEF 8028 will later become beauveria_bassiana_arsef_8028 in the database.

```
funannotate train --cpus 20 \
    -i ARSEF8028_contigs_sorted.fasta -o BEA_train_output \
    --left SRR3269778_1_cleaned.fastq SRR3269779_1_cleaned.fastq SRR3269780_1_cleaned.fastq SRR15242230_1_cleaned.fastq \
    --right SRR3269778_2_cleaned.fastq SRR3269779_2_cleaned.fastq SRR3269780_2_cleaned.fastq SRR15242230_2_cleaned.fastq \
    --species "Beauveria bassiana" --strain "ARSEF 8028" \
    --jaccard_clip 
```

For this size of data, it took 4-5 hours to complete the job.

Successful training should produce a message such as this in the logs:
```
[Mar 02 09:26 PM]: Wrote 9,267 PASA gene models
[Mar 02 09:26 PM]: PASA database name: Beauveria_bassiana_ARSEF_8028
[Mar 02 09:26 PM]: Trinity/PASA has completed, you are now ready to run funanotate predict, for example:

  funannotate predict -i ARSEF8028_masked.fasta \
            -o BEA_train_output -s "Beauveria bassiana" --strain ARSEF 8028 --cpus 24
```

### Funannotate predict to store pretrained data

In the same directory where the funannotate train output was placed, we will run funannotate predict.

* Likely to take hours depending on size.
* For the first run, input (-i) and output (-o) should be identical to funannotate train so the training data is used.
* If not using a masked input, add –force to the funannotate predict command.
* –name is where you can input the locus tag name given from NCBI.
  * If you don’t have this yet, you can use a placeholder like “bea” and later replace “bea” with the locus tag.
* Funannotate predict description: Script takes genome multi-fasta file and a variety of inputs to do a comprehensive whole genome gene prediction.
  * Uses AUGUSTUS, GeneMark, Snap, GlimmerHMM, BUSCO, EVidence Modeler, tbl2asn, tRNAScan-SE, Exonerate, minimap2.

```
funannotate predict --cpus 20 --force \
    -i ARSEF8028_sorted.fasta -o BEA_train_output \
    --species "Beauveria bassiana" --strain "ARSEF 8028" --name bea 
```

After submitting the sbatch, you can confirm the training files were used in the logs:
```
[Mar 03 02:50 PM]: Found training files, will re-use these files:
  --rna_bam BEA_train_test_output/training/funannotate_train.coordSorted.bam
  --pasa_gff BEA_train_test_output/training/funannotate_train.pasa.gff3
  --stringtie BEA_train_test_output/training/funannotate_train.stringtie.gtf
  --transcript_alignments BEA_train_test_output/training/funannotate_train.transcripts.gff3
[Mar 03 02:50 PM]: Parsed training data, run ab-initio gene predictors as follows:
  Program        Training-Method
  augustus       pasa
  codingquarry   rna-bam
  genemark       selftraining
  glimmerhmm     pasa
  snap           pasa
```

When the job is completed, the logs should end like this:
```
[Mar 03 04:09 PM]: 10,574 gene models remaining
[Mar 03 04:09 PM]: Predicting tRNAs
[Mar 03 04:11 PM]: 115 tRNAscan models are valid (non-overlapping)
[Mar 03 04:11 PM]: Generating GenBank tbl annotation file
[Mar 03 04:11 PM]: Collecting final annotation files for 10,689 total gene models
[Mar 03 04:11 PM]: Converting to final Genbank format
[Mar 03 04:11 PM]: Funannotate predict is finished, output files are in the BEA_train_test_output/predict_results folder 
[Mar 03 04:11 PM]: Your next step to capture UTRs and update annotation using PASA:

  funannotate update -i BEA_train_test_output --cpus 40

[Mar 03 04:11 PM]: Training parameters file saved: BEA_train_test_2_output/predict_results/beauveria_bassiana_arsef_8028.parameters.json
[Mar 03 04:11 PM]: Add species parameters to database:

  funannotate species -s beauveria_bassiana_arsef_8028 -a BEA_train_test_output/predict_results/beauveria_bassiana_arsef_8028.parameters.json
```

As stated in the last message, we can run funannotate species to add the training parameters file to the database. Then our other genomes can run with pretrained data.
```
funannotate species -s beauveria_bassiana_arsef_8028 -a BEA_train_test_output/predict_results/beauveria_bassiana_arsef_8028.parameters.json
```

Future runs utilizing this training will have this message in the logs:
```
[Mar 07 01:59 PM]: Parsed training data, run ab-initio gene predictors as follows:
  Program      Training-Method
  augustus     pretrained
  genemark     pretrained
  glimmerhmm   pretrained
  snap         pretrained
```

### Steps before mass running funannotate predict
These are NCBI issues that may delay submissions later on. Doing this now can prevent needing to rerun funannotate predict later.

### Obtain locus tags from NCBI
* Visit https://submit.ncbi.nlm.nih.gov/ and fill form for GenBank submission.
* During process, should receive e-mail with locus tag for each genome.
* Doing this will allow you to assign the tag to the –name in the predict step for each genome.

### Remove mitochondria from genome contigs files

### Check for Ns > 100 in contigs files. Split sequences with this issue into two.

### Funannoate predict parallel processing with Slurm array
Now it is possible to mass run funannotate predict using the pretrained data. Pretrained data is called by –augustus_species.

We had approx. 65 samples to run, so a Slurm array setup allowed parallel processing of multiple samples at the same time. This example comes from: funannotate_sbatch_scripts/3_sbatch_array_funannotate_predict.sh
```
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
```

## What is the protein and transcript evidence?
Details can be found at: https://funannotate.readthedocs.io/en/latest/evidence.html

By default, the predict command uses the UniProt/Swiss-Prot database as protein evidence. This is suitable for most studies because the UniProt database is curated.

To be on the safe side, we specify the –protein_evidence parameter to the location where the database was setup: –protein_evidence $FUNANNOTATE_DB/uniprot_sprot.fasta

Next, the –transcript_evidence is obtained by running RNA-seq data through an assembler. As an example, we used the same RNA-seq data from the above sections, ran it through the SPAdes assembler, and concatenated the sequences into a transcripts fasta file. –transcript_evidence transcripts_BEA.fasta

## 2. Alternative method: train Augustus on BUSCO predictions

From advice given by Funannotate author Jon Palmer, we found this method to be as effective as the RNA-seq method. “If you pass the —busco_seed_species fusarium_graminearum then it will use that pre-trained models to start/guide the BUSCO predictions — but then will use those results to train augustus on your _B. bassiana_ genome.”

In other words, we can use a closely related species already in the Augustus species list, _Fusarium graminearum_, to inform the BUSCO predictions, but then have Augustus train on _Beauveria bassiana_.

This is different that specifying –augustus_species (or –species) fusarium_graminearum. This would use pretrained Augustus data for fusarium_graminearum and it would not be trained on _Beauveria bassiana_. Therefore, it is important to use –busco_seed_species for this method.

Lastly, –busco_db is set to dikarya by default. Since we know our species, we can narrow this down. Although hypocreales (order level) was not available in Funannotate, we were able to use sordariomycetes (class level) (need to install, but it is straightforward).

List of BUSCO fungi groups here: https://busco.ezlab.org/frames/fungi.htm

```
funannotate setup -b sordariomycetes

funannotate predict --cpus 20 --force \
-i ARSEF8028_contigs_sorted.fasta -o ARSEF8028_OUTPUT \
  --species "Beauveria bassiana" --strain "ARSEF 8028" --name bea \
  --protein_evidence $FUNANNOTATE_DB/uniprot_sprot.fasta --transcript_evidence transcripts_BEA.fasta \
  --busco_seed_species fusarium_graminearum --busco_db sordariomycetes
```

After this run is complete, run funannotate species to add the training data to the database.

(If testing both methods, would need to change -s to a different name to have two separate database entries)
```
funannotate species -s beauveria_bassiana_arsef_8028 -a ARSEF8028_OUTPUT/predict_results/beauveria_bassiana_arsef_8028.parameters.json
```

Now funannotate predict can be run using a Slurm array on the other genomes as in the above section.

## Functional annotation

### Optional: Run InterProScan5
We ended up skipping this step because the program requires a lot of time and resources, but according to funannotate it can help with the final annotation.

The standalone InterProScan program was tested, due to an error with Funannotate's command for InterProScan.

```
module load interproscan

PROTEINS_DIR=ARSEF8028_OUTPUT/predict_results

interproscan.sh -i ${PROTEINS_DIR}/Beauveria_bassiana_ARSEF8028.proteins.fa -f XML -goterms -pa

mv Beauveria_bassiana_ARSEF8028.proteins.fa.xml ARSEF8028_OUTPUT/annotate_misc/iprscan.xml
```

iprscan.xml is the file Funannotate will use later.

### Run antiSMASH

There is a funannotate remote command for antiSMASH, but it is prone to errors. You can install antismash through conda. https://docs.antismash.secondarymetabolites.org/install/

Update: SCINet now has a module for antiSMASH.

The example below is for a conda-installed antismash.
```
source activate /project/entfun/PHILIP_FUNGI_PROJECT/software/antiSMASH

antismash --taxon fungi \
    --output-dir ARSEF8028_OUTPUT/antiSMASH_results \
    --output-basename ARSEF8028_antiSMASH \
    --genefinding-tool none \
    ARSEF8028_OUTPUT/predict_results/Beauveria_bassiana_ARSEF_8028.gbk
```

### Optional: Run Phobius
As mentioned with antiSMASH, the remote command is prone to errors, but this step can be skipped.

```
funannotate remote -i ARSEF8028_OUTPUT -m phobius -e your-email@usda.gov
```

## Funannotate annotate

### Install EggNOG-mapper
Need to specify version 2.1.9 because v2.1.10 will NOT work with this Funannotate version (it would run EggNog but the results would not be parsed into the annotation).

Do this when the Funannotate environment is activated, and it will automatically install where Funannotate needs it.

Make a data directory inside the site-packages directory (where Funannotate stores python scripts).

Run download_eggnog_data.py to obtain the annotation db and diamond db (the 2nd option for taxa db can be skipped).

```
pip install eggnog-mapper==2.1.9

cd /project/entfun/PHILIP_FUNGI_PROJECT/software/funannotate_1.8.15/lib/python3.8/site-packages

mkdir data

download_eggnog_data.py
```

### Run funannotate annotate
“It pulls annotation from PFAM, InterPro, EggNog, UniProtKB, MEROPS, CAZyme, and GO ontology.”

The program should incorporate the InterProScan5, antiSMASH, and Phobius results if the previous steps completed correctly and the files are present in annotate_misc. EggNog will be run in the middle of this script. This example will only incorporate antiSMASH.

The annotate_results folder will have the final .tbl, .sqn, .gbk, etc. results files.
```
funannotate annotate  --cpus 20 --force \
    -i ARSEF8028_OUTPUT --sbt template_BEA_rehner.sbt \
    --species "Beaveria bassiana" --strain "ARSEF 8028" \
    --antismash ARSEF_8028_OUTPUT/antiSMASH_results/ARSEF_8028_antiSMASH.gbk \
    --busco_db sordariomycetes
```

## Submit to NCBI and perform final cleanup
Gather the .sqn files from annotate_results, download them, and submit them to NCBI GenBank. When the .sqn files are submitted, NCBI will produce reports listing errors that must be corrected.

The contamination.txt file will list mitochondria and adapters found in sequences. The mitochondria should be removed from the contigs files and placed into a separate file for mitochondria.

For the contigs with sequences removed, the funannotate steps will need to be repeated to account for those sequences no longer being there. It is recommended to keep organized sbatch scripts so the steps can easily be rerun if necessary.

## Post-processing: Genome coverage
NCBI asks for genome coverage when the raw sequences are submitted. Use a folder containing the original contigs to calculate the genome coverage. 

### First, run bowtie2 to build an index
```
module load bowtie2

cd /project/entfun/PHILIP_FUNGI_PROJECT/library/BEA/funannotate/contigs

mkdir index

bowtie2-build A04_25_contigs.fasta index/A04_25_contigs
```

### Run bowtie2 to make a .sam file
```
#! /bin/bash

#SBATCH --job-name="bowtie21"
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 20
#SBATCH -t 24:00:00
#SBATCH --mail-user=your.name@usda.gov
#SBATCH --mail-type=END,FAIL
#SBATCH -o "stdout.%j.%N"

date

INPUT_DIR=/project/entfun/CLEANED_SEQUENCES

module load bowtie2

bowtie2 -p 20 -x index/A04_25_contigs \
	-1 ${INPUT_DIR}/run1_cleaned_reads_R1.fastq \
	-2 ${INPUT_DIR}/run1_cleaned_reads_R2.fastq \
	-1 ${INPUT_DIR}/run2_cleaned_reads_R1.fastq \
	-2 ${INPUT_DIR}/run2_cleaned_reads_R2.fastq \
	-1 ${INPUT_DIR}/run3_cleaned_reads_R1.fastq \
	-2 ${INPUT_DIR}/run3_cleaned_reads_R2.fastq \
	--al-conc--gz A04_25_map.fastq.gz -S A04_25_map.sam

date
```

### Run bbtools on the .sam file produced in the last step
The output will have an “Average coverage” that will be used in the NCBI submission.

```
module load bbtools

pileup.sh in=A04_25_map.sam covstats=A04_25_coverage.txt
```

Sample output. Enter the “Average coverage” into the Genome Batch file from NCBI.
```
Reads:                                  15754650
Mapped reads:                           15304545
Mapped bases:                           2226764995
Ref scaffolds:                          1448
Ref bases:                              59707322

Percent mapped:                         97.143
Percent proper pairs:                   79.899
Average coverage:                       37.295
Average coverage with deletions:        37.259
Standard deviation:                     59.918
Percent scaffolds with any coverage:    91.85
Percent of reference bases covered:     99.97
```
