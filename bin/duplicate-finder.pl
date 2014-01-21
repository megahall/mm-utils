#!/usr/bin/perl

use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper;
use Digest::SHA;
use File::Find;
use Time::HiRes qw(time);

no warnings "File::Find";

$Data::Dumper::Indent = 1;

my $path_table = {};
my $size_table = {};
my $hash_table = {};
my $files      =  0;
my $i          =  0;

$| = 1;

sub collect_paths {
    my $file    = $_;
    my $path    = abs_path($file);
    my $is_file = -f _;
    my $size    = -s _;
    return unless $is_file && $size >= 512;
    $size_table->{$size}->{$path} = 1;
    $path_table->{$path} = $size;
    ++$files;
}

my $start_time = time();

find({ 'wanted' => \&collect_paths, 'no_chdir' => 1 }, @ARGV);

my @size_list = sort { $b <=> $a } (keys(%$size_table));
my $size_count = @size_list;
foreach my $size (@size_list) {
    #print "checking size [$size] [$i / $size_count]\n";
    my @paths = keys(%{$size_table->{$size}});
    goto end unless @paths > 1;
    
    print "inspecting size [$size] [$i / $size_count]\n";
    foreach my $path (@paths) {
        #print "inspecting file [$path]\n";
        my $hash = undef;
        eval {
            my $sha = Digest::SHA->new(256);
            $sha->addfile($path);
            $hash = uc($sha->hexdigest());
        };
        #print "warning: file [$path] raised error [$@]\n" if !$hash || $@;        
        next unless $hash;
        $hash_table->{$hash}->{$path} = 1;
    }
    
    end:
    ++$i;
}

#print Dumper($size_table);
#print Dumper($hash_table);
#print Dumper($path_table);
while (my ($hash, $paths) = each(%$hash_table)) {
    my @paths = keys(%$paths);
    next unless @paths > 1;
    my $path_string = "\n    " . join("\n    ", sort(@paths)) . "\n";
    my $size = $path_table->{$paths[0]};
    print "hash [$hash] size [$size] present at:\n";
    foreach my $path (@paths) {
        print "    $path\n";
    }
}

my $end_time = time();

my $elapsed_time = $end_time - $start_time;

print "inspected [$files] files in [$elapsed_time] secs.\n";

exit(0);
