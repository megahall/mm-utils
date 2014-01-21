#!/usr/bin/perl

use strict;
use warnings;

$/ = "\0";

my $filter = $ARGV[0];

while (<STDIN>) {
    print $_ if $_ =~ /$filter/i;
}

exit(0);
