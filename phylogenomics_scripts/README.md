# Phylogenomics by extracting UCE loci

## Techniques used
Numbers here correspond to the number in script files.

1. Extract UCE loci using Phyluce software
    * https://phyluce.readthedocs.io/en/latest/
    * Script called make_directories_for_extract.py can be used to prepare for this step
2. Move extracted sequences into locus specific folders with custom Python script
3. Sequence alignment with MAFFT on the locus specific outputs
4. Gblocks program to address poorly aligned positions and divergent regions
    * https://home.cc.umanitoba.ca/~psgendb/doc/Castresana/Gblocks_documentation.html
5. Count alignment length and output partitions file with custom Python script
6. IQ-TREE for phylogenomic inference
    * https://iqtree.github.io/

The workflow in full detail is below.

## 1. Extract UCE loci using Phyluce software

### Copy CDS transcripts files to one directory
Using the BEA set of genomes as an example, I made a directory called BEA_CDS_transcripts. I copied the CDS transcripts to this location. The file names looked like this: Beauveria_bassiana_ARSEF_1079.cds-transcripts.fa 

### Process files to convert to 2bit
Make a list of every file ending in .fa and save it in a text file.
```
ls *.fa > list_of_samples.txt

nano list_of_samples.txt
```

In nano, use Ctrl + \ and use the replace tool to remove .fa from all samples. Save and exit.

Copy this list:
```
cp list_of_samples.txt list_of_2bits.txt

nano list_of_2bits.txt
```

Use the replace tool to simplify these file names. For example,

Beauveria_bassiana_ARSEF_1079.cds-transcripts

Delete “Beauveria_bassiana_”, “cds-transcripts”, and the “_” after ARSEF so the name will be:

ARSEF1079

### Important to avoid future error:
These names should not have dashes. E.g. if you have a name such as SAR11-511, change it to SAR11_511!

One of the scripts has problems reading dashes.

### Read arrays and loop faToTwoBit conversion

First, make sure a copy of faToTwoBit is in the folder.

These commands will make 2 arrays from the lists made, and then loop the faToTwoBit command on all the samples in the list.

```
readarray -t SampleList < list_of_samples.txt

readarray -t TwobitList < list_of_2bits.txt

for i in "${!SampleList[@]}"; do ./faToTwoBit "${SampleList[i]}".fa "${TwobitList[i]}".2bit ; done
```

What the loop does is obtain the input by filling “${SampleList[i]}” with “Beauveria_bassiana_ARSEF_1079.cds-transcripts” and name the output by filling “${TwobitList[i]}” with “ARSEF1079”. This repeats for every sample in the lists.

### Python script for making transcript directories

Now there should be many files such as ARSEF1079.2bit. We need to make a directory for every genome and move the respective .2bit inside, and I made a Python script to do this.

```
python make_directories_for_extract.py
```

Summary of what the script does:
* 1st for twobit in twobits:
  * Takes ARSEF1079.2bit, removes the .2bit to obtain sample name “ARSEF1079”, appends sample name to the samples array.
* for sample in samples:
  * Makes the new directory using the sample name “ARSEF1079”.
  * Next is making the script recognize the .fa files which would have “_” in their names. I add an underscore e.g. “ARSEF_1079” and save it to an ids array.
* 2nd for twobit in twobits:
  * Specifies a dirname that the 2bit file will be moved to, e.g. ARSEF1079/ARSEF1079.2bit
  * os.rename moves the file there
* for fasta in fastas:
  * The re.search part should match the common name patterns such as ARSEF_ or SAR#-
  * If there is a match with an entry in the ids array, specify a dirname and move the file there.

### Alternative if using different naming patterns
In case the script didn’t move .fa files because it didn’t recognize the naming patterns, you can use this bash loop that utilizes the same arrays from the faToTwoBit step.

```
for i in "${!SampleList[@]}"; do mv "${SampleList[i]}".fa "${TwobitList[i]}" ; done
```

The location of the .2bit is the part that actually matters, but it’s nice to not have the .fa cluttering the directory.

### genomes_BEA1.conf Formatting
You may notice in 1_sbatch_extract_CDS_BEA.sh an input called genomes_BEA1.conf. This is a text file listing the filepaths to the .2bit files. The first line should say “[scaffolds]”. Each line after needs to have a sample ID with a colon, followed by the filepath of the .2bit file.

I made an Excel template where you can fill in the the sample IDs and the filepath, and the last column will combine everything. Copy the contents of the last column into a text file.

```
[scaffolds]
ARSEF1079:/project/entfun/PHILIP_FUNGI_PROJECT/library/CDS_BEA_xtr/2023_extract/BEA_CDS_transcripts/ARSEF1079/ARSEF1079.2bit
ARSEF10969:/project/entfun/PHILIP_FUNGI_PROJECT/library/CDS_BEA_xtr/2023_extract/BEA_CDS_transcripts/ARSEF10969/ARSEF10969.2bit
ARSEF11065:/project/entfun/PHILIP_FUNGI_PROJECT/library/CDS_BEA_xtr/2023_extract/BEA_CDS_transcripts/ARSEF11065/ARSEF11065.2bit
...
```

### Run sbatch script for extracting CDS

Parameters for phyluce_probe_run_multiple_lastzs_sqlite
* --db: name of the database output file
* --output: name of the folder that will contain lastz output
* --scaffoldlist: list every genome that you want processed. This should match the folder names in BEA_CDS_transcripts
* --genome-base-path: folder containing the transcripts, in this case BEA_CDS_transcripts
* --probefile: Fasta of loci to be extracted. In this case, it was a file prepared by Dr. Rehner containing 502 odb loci.

Parameters for phyluce_probe_slice_sequence_from_genomes
* --lastz: should match –output from above
* --conf: a text file ending in .conf (as mentioned above)
* --flank: 0 if looking to extract exact sequence
* --name-pattern: a naming pattern with beginning matching the –probefile
* --output: any name you want for extraction output

```
sbatch 1_sbatch_extract_CDS_BEA.sh
```

## 2. Locus specific folders

The default extraction output has results for each genome sample, e.g. arsef1079.fasta. This workflow groups the extracted sequences together based on the locus, or odb ID.

### Reformatting fasta headers

Go inside the extract output folder.

Make a list of the fasta files and read into array.

```
ls *.fasta > list_of_fastas.txt

readarray -t FastaList < list_of_fastas.txt
```

Loop through array with sed command to remove unnecessary information. This results in a format of >samplename|odblocus, e.g. >arsef1079|142
```
for i in ${FastaList[@]};
    do sed -e 's/>.*uce-/>'"$i"'~/' -e 's/|.*//' -e 's/~/|/' "$i".fasta > "$i"_headers.fasta ; 
done
```

### Running the Python script
Up to you, you can move the modified fastas to a separate folder. I concatenated the modified headers files to 1 file called all_extracted_seqs.fasta. Then I ran grep this file to make a list of loci IDs. These serve as the input files to my custom Python script.

```
mkdir modified_headers

mv *_headers.fasta modified_headers

cd modified_headers

cat *_headers.fasta > all_extracted_seqs.fasta

grep ">" all_extracted_seqs.fasta | sed 's/>.*|//' | sort | uniq > loci_list_no_dupes.txt

mkdir locus_specific_folders

mv all_extracted_seqs.fasta loci_list_no_dupes.txt locus_specific_folders/

cd locus_specific_folders

python locus_specific_folders.py all_extracted_seqs.fasta loci_list_no_dupes.txt
```

Now there should be many folders starting with “odb_”.

## 3. Alignment with MAFFT
Uses the fasta file in each "odb_" folder as input.
```
cd locus_specific_folders

mkdir NEXUS

sbatch 3_sbatch_array_MAFFT.sh
```

## 4. Run Gblocks
This script will make a list of fastas from the alignment output, grep the number of sequences, and calculate 50% + 1 of those sequences for each file. The calculation is used as one of the Gblocks parameters. Then it runs Gblocks in a loop and handles some preparation steps to next run IQ-TREE.

```
cd NEXUS

sbatch 4_sbatch_loop_gblocks.sh
```

## 5. Make partitions files by counting alignment length.
We need to make partitions files that will be used for the sbatch in the later step. I made a Python script called count_alignment_length.py to do this. It is already part of 4_sbatch_loop_gblocks.sh, so you do not need to run it separately unless a step failed.

To run the script separately, you only need to have Python active:
```
python 5_count_alignment_length.py
```

For example, the script will create a file like this if the alignment length is 2457:
```
DNA, part1 = 1-2457\3
DNA, part2 = 2-2457\3
DNA, part3 = 3-2457\3
```

## 6. IQ-TREE for phylogenomics inference
ML Gene Trees method suggested by Chris Owen. Thank you to Chris for suggestions in structuring the array setup in the sbatch file.

```
ls *.fasta > gene_tree_array

sbatch 6_sbatch_array_iqtree.sh
```
