#!/usr/bin/perl

use strict;
use warnings;

$/ = "\0";

my $skip = int($ARGV[0]);
my $count = 0;

while (<STDIN>) {
    if (++$count <= $skip) {
        chomp;
        print STDERR "skipping $count: $_\n";
    }
    else {
        print $_;
        
        #if $count && ($count % 10 == 0) {
        #    chomp;
        #    print STDERR "***** FILE COUNT $count PATH $_\n";
        #}
    }
}

exit(0);
