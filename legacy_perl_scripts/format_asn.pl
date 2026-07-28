#! /usr/bin/perl

use warnings;
use strict; 

my $file = shift;
open(IN,$file) || die "can't open file\n";

my $count;

my $file2 = shift;
open(IN2,$file2) || die "can't open file\n";

my @array_id;
my @array_description;
my $i=0;

while (<IN2>)
{
        if (/(.*)/)
        {
                my $line=$1;
                my @array_line = split(/\t/, $line);
                $array_id[$i]=$array_line[0];
		my $description =$array_line[1];
		#[gnl|ncbi|bea_000071-T1:1-66]
		#$description=~  s/\[Beauveria bassiana ARSEF 2860\]//g;
		#$description=~  s/\[gnl|ncbi|bea_000071-T1:1-66\]//g; 
		#$description=~ s/\[.*\]//g; 
		$array_description[$i]=$description;
		#print "$array_line[0]\t$description\n"; 
		$i++;

        }

}#end while

=fornobody
>Feature NODE_1
1	259403	REFERENCE
			CFMR	12345
<204	729	gene
			locus_tag	bea_000001
204	309	mRNA
420	594
651	729
			product	hypothetical protein
			transcript_id	gnl|ncbi|bea_000001-T1
			protein_id	gnl|ncbi|bea_000001-T1
204	309	CDS
420	594
651	729
			codon_start	1
			product	hypothetical protein
			transcript_id	gnl|ncbi|bea_000001-T1
			protein_id	gnl|ncbi|bea_000001-T1
2401	937	gene
			locus_tag	bea_000002
2401	2051	mRNA
1993	1741
1679	937
			product	hypothetical protein
			transcript_id	gnl|ncbi|bea_000002-T1
			protein_id	gnl|ncbi|bea_000002-T1
2401	2051	CDS
1993	1741
1679	>937


240542	240622	gene
			locus_tag	bea_002461
240542	240622	tRNA
			product	tRNA-Pro

=cut

while (<IN>)
{
	if(/(>Feature.*)/)
	{
		print "$1\n";
	}

	if(/			locus_tag	/)
	{
		print "$_";
	}

	if(/([<>]?[0-9]*)\t([<>]?[0-9]*)\tgene/)
	{
		print "$_";
	}

	if(/([<>]?[0-9]*)\t([<>]?[0-9]*)\tmRNA/)
	{
		print "$_";
	}
	if(/([<>]?[0-9]*)\t([<>]?[0-9]*)\tCDS/)
        {
                print "$_";
        }

	if(/^([<>]?[0-9]*)\t([<>]?[0-9]*)$/)
	#if(/^([0-9]*)	([0-9]*)$/)
	{
		print "$_";
	}
        if(/			codon_start	[0-9]/)
        {
                print "$_";
        }

        if(/([<>]?[0-9]*)\t([<>]?[0-9]*)\ttRNA/)
        {
                print "$_";
        }
       
	if(/			product	tRNA-*/)
	{
                print "$_";
	}

	if(/			protein_id	gnl\|ncbi\|(bea_.*)/)
	{
		#print "$_";
		my $id=$1;
		for (my $z=0;$z<=$#array_id;$z++)
		{	
			if($array_id[$z] eq $id)
			{
				print"                        product\t$array_description[$z]\n"; 

			
			print $_;
			print "                        transcript_id      gnl|ncbi|$id\n";
			}
		}
		
	}

        #if(/                    protein_id.*/)
        #{
        #        print "$_";
        #}

	# if(/			product.*/)
	# {
	#         print "$_";
	# }

}#end while
