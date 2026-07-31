#!/usr/bin/env python3

import glob, sys, re
from pathlib import Path

# Loop through fasta files (run script inside same folder as fastas)
for file in glob.glob('*.fasta'):
        # Open a file
        with open(file, 'r') as fasta:
                # Reset the header and length variables.
                header = None
                length = 0
                # Loop through lines in fasta file.
                for line in fasta:
                        # Trim newline
                        line = line.rstrip()
                        # Find header
                        if line.startswith('>'):
                                # After the alignment length is counted, the header will not be None. Therefore, we can start writing to a new file.
                                if header is not None:
                                        print("Alignment length of " + fasta.name + ":", length)
                                        # Next 3 lines to set up output file name and partitions folder for output location.
                                        file_name = re.sub('.fasta', '_parts.txt', fasta.name)
                                        save_path = Path("partitions")
                                        save_path.mkdir(exist_ok = True)
                                        # Write 3 lines in the IQ-TREE format including the alignment length.
                                        with open(save_path / file_name, 'w') as fo:
                                                fo.write("DNA, part1 = 1-" + str(length) + r"\3" + "\n")
                                                fo.write("DNA, part2 = 2-" + str(length) + r"\3" + "\n")
                                                fo.write("DNA, part3 = 3-" + str(length) + r"\3" + "\n")
                                        # Only need to count alignment length once, so break the loop here.
                                        break
                                header = line[1:]
                        # Count the alignment length (knowing the line without ">" is a sequence)
                        else:
                                length += len(line)