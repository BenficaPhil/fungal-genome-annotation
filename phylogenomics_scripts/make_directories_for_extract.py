#!/usr/bin/env python3

import os, glob, re

fastas = glob.glob('*.fa')
twobits = glob.glob('*.2bit')
samples = []
ids = []

for twobit in twobits:
    sample = re.sub(".2bit", "", twobit)
    samples.append(sample)

for sample in samples:
    os.mkdir(sample)
    sample_id = re.sub(r'([a-zA-Z]+)', r'\1_', sample)
    ids.append(sample_id)

#print(ids)

print("Directories created for each sample in this directory.")

for twobit in twobits:
    dirname = re.sub(".2bit", "", twobit) + "/" + twobit
    os.rename(twobit, dirname)

for fasta in fastas:
    fileid = re.search(r'[a-zA-Z]+_[0-9]+-?[0-9]+', fasta)
    #print(fileid.group(0))
    if fileid.group(0) in ids:
        #print("matched this ID: " + fileid.group(0))
        dirname = re.sub("_", "", fileid.group(0)) + "/" + fasta
        os.rename(fasta, dirname)

print("Fasta and 2bit files have been moved to the new directories.")