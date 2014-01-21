#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use File::Find;

sub dirent_count {
    return unless -d;
    
    my $i = 0;
    opendir(my $dir, $_) || die $!;
    ++$i while readdir($dir);
    closedir($dir);
    
    printf("%06d %s\n", $i, $File::Find::name);
}

@ARGV = "." unless scalar(@ARGV);

find(\&dirent_count, @ARGV);
