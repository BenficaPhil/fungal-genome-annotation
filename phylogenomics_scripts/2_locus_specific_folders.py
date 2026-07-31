#!/usr/bin/env python3

###########################################################################################
# Script to read fasta file containing all extracted sequences and split sequences from the 
# same locus (odb ID) into its own folder and file named with the odb ID.
# E.g. the output odb_10007 will include the sequences for this locus from the different
# genome samples, allowing to later perform alignment.
# By Philip Campos in support of Dr. Stephen Rehner's fungal genomics work
###########################################################################################
import sys, re
from pathlib import Path

# Accept two inputs. The command is: python locus_specific_folders.py file1 file2
# E.g. python locus_specific_folders.py all_extracted_seqs.fasta loci_list_no_dupes.txt
with open(sys.argv[1],'r') as f1, open(sys.argv[2], 'r') as f2:
	lines1=f1.readlines()
	lines2=f2.readlines()

# Regular expression (re) for fasta headers (hre) and lines with sequences (lre)
hre=re.compile('>(\S+)')
lre=re.compile('^(\S+)$')

# Arrays for headers, sequences, IDs (from a list of odb IDs). The 4th array takes headers 
# from the 1st array and stores only the ID at the end of the header, which later allows for 
# matches between idArray and hdridArray.
hdrArray=[]
seqArray=[]
idArray=[]
hdridArray=[]
sampleArray=[]

# Empty variable to prepare parsing sequences.
currentSeq=''

# For loop to read every line in the fasta input. Start by checking if line is a header.
# If yes, 1) append header to hdrArray and 2) append ID from header into hdridArray.
# Else, find sequence lines and combine them as one sequence until a new header is found.
# Final line appends sequence to seqArray.
for line in lines1:
        outh = hre.search(line)
        if outh:
                hdr=outh.group(1)
                hdrArray.append(hdr)
                hdrid=re.sub('.*\|', '', hdr)
                hdridArray.append(hdrid)
                sample=re.sub('\|.*', '', hdr)
                sampleArray.append(sample)
                if currentSeq != '':
                       seqArray.append(currentSeq)

                currentSeq = ''
        else:
                outl=lre.search(line)
                seq=outl.group(1)
                currentSeq += seq

seqArray.append(currentSeq)

# For loop to grab IDs from file2 input.
for line in lines2:
        outi=lre.search(line)
        id=outi.group(1)
        idArray.append(id)

# Line 1) Loop through idArray
# Line 2) Set up j to be called later and direct which header+sequence is printed and how the output will be named.
# Line 3) Condition: if match ID from file2 (list of odb IDs) with ID from header
# Lines 4+) Specify save_path to make a new folder, file_name to name fasta file based on id. "with open" to write a new file 
# and print output there.  
for i in range(len(idArray)):
        save_path = Path("odb_" + idArray[i])
        file_name = "odb_" + idArray[i] + ".fasta"
        save_path.mkdir(exist_ok = True)
        with open(save_path / file_name, 'w') as fo:
                for j in range(len(hdridArray)):
                        if idArray[i] == hdridArray[j]: 
                                with open(save_path / file_name, 'a') as fo:
                                        fo.write(">" + sampleArray[j] + "\n" + seqArray[j] + "\n")
