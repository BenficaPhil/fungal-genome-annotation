#! /usr/bin/perl

use warnings;
use strict;

my $file = shift;
open(IN,$file) || die "can't open file\n";

my $count;

my @array_id;
my @array_description;
my $i=0;

#coll_000120-T1  Hydrolyase ccsE [Colletotrichum siamense]	XP_036501541.1  0.0
#coll_000121-T1  Efflux pump FUS6 [Colletotrichum siamense]	XP_036501544.1  0.0
#coll_000122-T1  uncharacterized protein CGMCC3_g14075 [Colletotrichum fructicola]	XP_031879277.1  0.0
#coll_000123-T1  uncharacterized protein CGMCC3_g14076 [Colletotrichum fructicola]	XP_031879399.1  0.0
#coll_000124-T1  uncharacterized protein CGMCC3_g14077 [Colletotrichum fructicola]	XP_031879327.1  0.0
#coll_000125-T1  uncharacterized protein CGMCC3_g14079 [Colletotrichum fructicola]	XP_031879266.1  0.0

while (<IN>)
{
        if (/(.*)\t(.*)\t(.*)/)
        {
                my $description=$1;
                $description=~ s/\[.*\]//g;
                $description=~  s/[Uu]ncharacterized.*/hypothetical protein/g;

                print "$description\n";
        }

}#end while