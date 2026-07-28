# Legacy method for manual curation of protein names
Prior to updating to the new Funannotate versions, we took the funannoate predict results and did NOT run them in "funannotate annotate". Instead, an NCBI database was made and the protein names were curated manually. The newer annotate pipeline allows us to avoid the manual curation.

## Download NCBI RefSeq fungi assemblies
1. Visit https://www.ncbi.nlm.nih.gov/assembly/ and enter all[filter] in the search bar.
2. In the left-sided menu, click on Fungi under Organism group. This will show only fungal assemblies.
3. To download all the RefSeq fungi assemblies, click on the Download Assemblies button, keep RefSeq as the Source database, and select File type Protein FASTA (.faa).

This database will be referred to as “fungi_ncbi”.

## Match proteins to NCBI databases
Make a folder for the databases. Upload and extract databases in this folder.
```
cd /project/entfun/PHILIP_FUNGI_PROJECT/ncbi_db
```

The contents should look like this:
```
fungi_ncbi.fasta.00.phr  fungi_ncbi.fasta.00.psq  fungi_ncbi.fasta.01.pin  fungi_ncbi.fasta.pal  fungi_ncbi.fasta.pot
fungi_ncbi.fasta.pto  fungi_ncbi.fasta.00.pin  fungi_ncbi.fasta.01.phr  fungi_ncbi.fasta.01.psq  fungi_ncbi.fasta.pdb
fungi_ncbi.fasta.ptf
```

Navigate to the predict_results folder created from the funannotate predict step. E.g.
```
cd /project/entfun/PHILIP_FUNGI_PROJECT/library/BEA/funannotate/A04_25_OUTPUT/predict_results
```

### IMPORTANT: Create a directory called temp inside predict_results
```
mkdir temp
```

### Sbatch script that will match proteins to the database
```
#! /bin/bash
#SBATCH --job-name="blastfun"
#SBATCH -p short
#SBATCH -N 1
#SBATCH -n 40
#SBATCH -t 48:00:00

date

INPUT_DIR=/project/entfun/PHILIP_FUNGI_PROJECT/library/BEA/funannotate/A04_25_OUTPUT/predict_results/

cp ${INPUT_DIR}/beauveria_bassiana_arsef_1816.proteins.fa $TMPDIR
cp /project/entfun/PHILIP_FUNGI_PROJECT/ncbi_db/f* $TMPDIR
cd $TMPDIR

module load blast+
module load parallel

cat beauveria_bassiana_arsef_1816.proteins.fa | \
parallel \
--block 50k \
--recstart '>' \
--pipe blastp \
-num_threads 40 \
-num_alignments 5 \
-num_descriptions 5 \
-db $TMPDIR/fungi_ncbi.fasta \
-query - > combined_results_A04_25_fungi_ncbi.txt

cp $TMPDIR/combined_results_A04_25_fungi_ncbi.txt ${INPUT_DIR}/temp

date
```

## Parse protein results
Place the blastparser.pl script (made by Jonathan Shao) into the funannotate folder.

Run blastparser.pl. This will produce a file listing all the protein names from the database matching results.
```
module load perl

perl ../../../blastparser.pl combined_results_A04_25_fungi_ncbi_PC.txt > combined_results_A04_25_fungi_ncbi_PC.parse
```

Review parse file and choose a database to continue with. We chose the fungi_ncbi database because having a larger database appeared to result in better matches and protein names.

## Fix protein names with Perl script
Place the fix.pl script (made by Jonathan) into the funannotate folder.

This script changes some names to “hypothetical protein” to be consistent with NCBI naming conventions.

Run fix.pl. Copy the result to make a version1.

```
module load perl

perl ../../../fix.pl combined_results_A04_25_fungi_ncbi_PC.parse > combined_results_A04_25_fungi_ncbi_PC.fix

cp combined_results_A04_25_fungi_ncbi_PC.fix combined_results_A04_25_fungi_ncbi_PC_fix.version1
```

## Manual fixes
1. Transfer the version1 file and beauveria_bassiana_arsef_1816.proteins.fa from predict_results to your computer.
2. Open the version1 file in Excel and scan through the list of protein names. The fix.pl standardized most names such as renaming unknown proteins to “hypothetical protein”. There will be some proteins with errors in the name or ambiguous names to correct. Examples are in the protein names checklist.
3. Below is the protein names checklist. This is applicable to _Beauveria_, but other organisms will have different errors that need to be solved.

```
blank cells

hypothetical protein

, partial

No_hits_found -> hypothetical protein

protein of unknown function -> hypothetical protein

unnamed protein product -> hypothetical protein

predicted protein -> hypothetical protein

antigen

(Naming proteins as antigens is discouraged but there may be rare exceptions to match widespread community/publication usage)

- antigenic cell wall galactomannoprotein, putative -> antigenic cell wall galactomannoprotein
- myosin-cross-reactive antigen -> myosin-cross-reactive antigen-like protein
- surface antigen -> SAM50-like protein SPA

cell surface

- cell surface metalloreductase (FreA) -> Ferric/cupric reductase transmembrane component 2 
- cell surface protein -> Mas1 protein
              Cyclin CCL1
              hypothetical protein
- cell surface protein, putative -> Collagen alpha-1(II) chain
- GPI-anchored cell surface glycoprotein -> GPI-anchored glycoprotein 
- protein required for amino acid permease transport from the Golgi to the cell surface -> Folliculin

secreted

- biotrophy-associated secreted protein 2 -> biotrophy-associated protein 2 
- putative secreted protein -> Protein-arginine deiminase type-4
                   Phospholipase A2
                   hypothetical protein
- putative salivary secreted peptide -> Phospholipase A2 
- secreted aspartic proteinase -> Candidapepsin-2 
- secreted lipase 1 precursor -> Lipase 1
                 Lipase 4
- secreted glucosidase -> Beta-glucanase 
- small secreted protein -> hypothetical protein

related to
- related to ankyrin -> hypothetical protein
- related to bikaverin cluster-transcription factor -> hypothetical protein
- related to PAN2-component of Pab1p-stimulated poly(A) ribonuclease -> PAN2-PAN3 deadenylation complex catalytic subunit PAN2
- related to short-chain dehydrogenase/reductase -> hypothetical protein
- related to UDP N-acetylglucosamine transporter (MNN2) -> hypothetical protein

MISC changes

- antifungal protein -> Cicadin
- ATPase associated with various cellular activities AAA_3 -> ATPase
- Fungal specific transcription factor, putative -> Proline utilization trans-activator
                            Transcription factor sdnS
                            Transcriptional activator of proteases prtT
                            hypothetical protein
- only prolin and serin are matching in the corresponding protein -> hypothetical protein
- protein (fungal and bacterial) -> hypothetical protein 
- protein (fungal and plant) -> hypothetical protein
- putative SERINE-TYPE CARBOXYPEPTIDASE F PRECURSOR -> serine-type carboxypeptidase
 
Remove "N-terminal", "N terminal", and "C terminal" from names
```

### BLAST proteins requiring name changes
Open the proteins.fa file and search the protein ID to find the sequence. Copy the sequence into BLASTp (link below) and choose a protein name.
https://blast.ncbi.nlm.nih.gov/Blast.cgi?PROGRAM=blastp&PAGE_TYPE=BlastSearch&LINK_LOC=blasthome

When done naming proteins, save file as .version2 and upload to the temp folder in SCINet.

### Insert locus tag
If the NCBI locus tag was not applied previously, open the .version2 file in nano.
```
nano combined_results_A04_25_fungi_ncbi_PC_fix.version2
```

Use Ctrl + \ to find “bea_” and replace with the NCBI locus tag. In our case, the locus tag was KHU50.

Use Ctrl + \ again to find quotation marks and replace them with nothing. When saving the file in Excel, quotation marks can appear around some names when opened as a text file and these should be deleted.

Save as .version3

### Save protein names to tbl format with format_asn.pl script
```
module load perl

perl format_asn.pl beauveria_bassiana_arsef_1816.tbl combined_results_A04_25_fungi_ncbi_PC_fix.version3 > A04_25.tbl
```

## Tbl2asn
At the time, we downloaded the tbl2asn script, however, this is now deprecated for table2asn.

In the predict_results folder, make a new directory called submit2ncbi. Tbl2asn requires .fsa and .tbl files.

After the files are copied, rename them so they have the same name but different file extensions.
```
mkdir submit2ncbi

cp beauveria_bassiana_arsef_1816.scaffolds.fa submit2ncbi

cp A04_25.tbl submit2ncbi

cd submit2ncbi

mv beauveria_bassiana_arsef_1816.scaffolds.fa A04_25.fsa
```

### Run tbl2asn
Run tbl2asn to produce .sqn files for GenBank submission. Change the strain name to the one that matches the organism in the output by checking the Master List.

More info on how these parameters work here: https://www.ncbi.nlm.nih.gov/genbank/tbl2asn2/

A template .sbt file with basic information is also required.

Filepath here assumes tbl2asn is three directories back. Adjust if file is located elsewhere.
```
../../../linux64.tbl2asn -M n -Z discrep -c f -t template_BEA_rehner.sbt -j "[organism=Beauveria bassiana] [strain=ARSEF 1816]" -p submit2ncbi/
```

### For mitochondrial submission
If running for mitochondrial submission, add these parameters to -j: [location=mitochondria] [gcode=4]

## Copy resulting .sqn file to your computer. Open in Sequin.
https://web.mit.edu/seven/src/ncbi/doc/sequin.htm

###  Note for possible error
If there was an issue and some information is missing, need to go back and make sure there is no space between the carrot > and Feature. Features is acceptable as well.
