#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use File::Find;
use JSON::PP;
use Video::Info;

my $parser = JSON::PP->new();

$parser->canonical(1);
$parser->indent(1);
$parser->indent_length(4);
$parser->relaxed(1);
$parser->space_before(1);
$parser->space_after(1);
$parser->utf8(1);

my $table = {};

sub check_video {
    my $file = $_;
    
    return unless -f $file && -s $file > 10485760;
    
    my $error  = "";
    my $width  = 0;
    my $height = 0;
    
    eval {
        local $SIG{ALRM} = sub { die "timed out\n" };
        alarm 5;
        
        my $info = Video::Info->new('-file' => $file);
        my $command = "mplayer -noconfig all -cache-min 0 -vo null -ao null -frames 0 -identify '$file' 2>/dev/null";
        print "executing [$command]";
        my $output = `$command`;
        exit(1);
        print "output:\n" . $output;
        $width   = $info->width();
        $height  = $info->height();
    };
    if ($@) {
        $error = $@;
        chomp($error);
    }
    
    my $bad_width  = $width  > 0 && $width  <= 320;
    my $bad_height = $height > 0 && $height <= 240;
    my $is_bad = ($bad_width || $bad_height) ? 1 : 0;
    
    print "checked [$file] size [$width x $height] error [$error]\n" if $error;
}

find({ 'wanted' => \&check_video, 'no_chdir' => 1 }, @ARGV);

print $parser->encode($table);
exit(0);
