#!/usr/bin/perl

use strict;
use warnings;

use POSIX qw(ctime);

my $block;
my @bytes;

my $start_time = time();
printf("start at %s", ctime($start_time));

foreach my $path (@ARGV) {
    open(my $file, "<", $path) || die "could not open $path";
    next if $path =~ /\.torrent$/;
    
    my @st      = stat($path);
    my $length  = $st[7];
    my $tblocks = 0;
    my $zblocks = 0;
    my $rv;
    #print "path $path length $length\n";
    
    while (($rv = sysread($file, $block, 1024)) != 0) {
        @bytes = unpack("C*", $block);
        ++$tblocks;
        
        my $is_zero = 1;
        for (my $i = 0; $i < scalar(@bytes); ++$i) {
            if ($bytes[$i]) {
                $is_zero = 0;
                goto not_zero;
            }
        }
        not_zero:
        ++$zblocks if $is_zero;
    }
    my $zpercent = (($zblocks * 1.0) / ($tblocks * 1.0)) * 100;
    printf("path %s zpercent %03.02f%%\n", $path, $zpercent) if $zpercent <= 99.0;
    close($file);
}

my $stop_time = time();
my $elapsed   = $stop_time - $start_time;

printf("stop at %s", ctime($stop_time));
printf("elapsed %d secs. %03.2f mins.\n", ctime($start_time), $elapsed, $elapsed / 60.0);
exit(0);
