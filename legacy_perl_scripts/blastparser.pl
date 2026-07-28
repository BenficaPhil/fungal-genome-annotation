#!/usr/bin/perl -w

# Parsing BLAST reports with BioPerl's Bio::SearchIO module
# WI Biocomputing course - Bioinformatics for Biologists - October 2003

# See help at http://www.bioperl.org/HOWTOs/html/SearchIO.html for all data that can be extracted

use Bio::SearchIO;
my $evalue;
my $first_hit;
my $hypothetical;
my $store_possible_hypthetical;
my $real_hypothetical="true"; 
my	$number_hits;
my	$result_query; 
my $result_hits;
my $hit_acc; 
    my $hit_count=0; 

# Prompt the user for the file name if it's not an argument
# NOTE: BLAST file must be in text (not html) format
if (! $ARGV[0])
{
   print "What is the BLAST file to parse? ";

   # Get input and remove the newline character at the end
   chomp ($inFile = <STDIN>);
}
else
{
   $inFile = $ARGV[0];
}

$report = new Bio::SearchIO(
         -file=>"$inFile",
              -format => "blast"); 

#note this program has a flaw in that it skips real hypothetical proteins
#print "QueryAcc\tHitDesc\tHitSignif\tHSP_rank\t\%ID\teValue\tHSP_length\n";

# Go through BLAST reports one by one              
while($result = $report->next_result) 
{  
     $result_hits=$result->num_hits;
     $result_query=$result->query_name; 
	$number_hits=$result_hits; 
	
	$hit_count=0;
	
	if ($result_hits ==0)
	{
		print "$result_query\tNo_hits_found\tgenbank\t999999\n";
	} 
   # Go through each each matching sequence
  
     	#my $dummy = $result->next_hit;
	#$number_hits=$dummy->num_hits;
   
	while($hit = $result->next_hit)
   	
   	{
	    $hit_acc=$hit->accession;
            $query = $result->query_accession;
            #$query =~ s/\.//g;
	    
	    
	    $description = $hit->description;
            #$description =~ s/\s//g;

		$evalue=$hit->significance;

  	 	if($hit_count ==0)
		{
		print "$query\t";
		print "$description\t";
		print "$hit_acc\t";
		print "$evalue\n";
		$hit_count=1; 
	 	}
	 	
  	 } #end hit while
	
}#end result while

=fornobody
	
#if ($description =~ //)
	#{
	#	print "query=$query\t";
	#	print "no hits found\n";
	#}
	# my $subj_start=$hsp->start('hit');
	# my $subj_end=$hsp->end('hit');
	# print "$subj_start\t";
	# print "$subj_end\t";
	# my $strand = $hsp->strand('hit');
	# "$strand\t";
	# my $subj_string=$hsp->hit_string;
	# print "$subj_string\t";

        # $hitacc = $hit->accession;
	# print "$hitacc\n";
	# print $hsp->percent_identity, "\n";
            
	# $count++;
=cut