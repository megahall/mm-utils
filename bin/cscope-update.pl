#!/usr/bin/env perl

use strict;
use warnings;

use Cwd qw(abs_path);
use Data::Dumper;
use File::Basename;
use File::Copy;
use File::Find;
use File::Path qw(make_path);
use File::Temp qw(tempfile);
use IO::Handle;
use POSIX qw(ctime);

$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse    = 1;

BEGIN { $| = 1; }

my $home_path = $ENV{'HOME'};
my $src_path  = $ENV{'SRCDIR'} || "$home_path/src";
die "SRCDIR $src_path is invalid" unless -d $src_path;

my @projects = grep { -d $_  } glob("$src_path/*");
print "scanning code from projects @projects\n";

my $project_path;
my $project;

my $cscope_file;
my $cscope_path;
my $count;
my $rv;

sub is_code_file {
    my $file = $_;
    
    lstat($file);
    my $path = abs_path($file);
    
    # symlinks to missing files will fail
    return unless $path && -f $path;
    
    return unless -f _ || -l _;
    return unless $file =~ /\.([chly](xx|pp)*|cc|hh)$/;
    
    return if $path =~ m%/\.%;
    return if $path =~ m%/.git/%;
    return if $path =~ m%/CVS/%;
    return if $path =~ m%/RCS/%;
    
    print $cscope_file "$path\n";
    ++$count;
    printf("%07d files found in project %s\n", $count, $project) if ($count != 0 && $count % 100 == 0);
}

for $project_path (@projects) {
    $project = basename($project_path);
    
    my $output_dir = "$home_path/cscope/$project";
    make_path($output_dir);
    
    $cscope_file = File::Temp->new('TEMPLATE' => "cscope.XXXX", 'SUFFIX' => '.files', 'DIR' => $output_dir, 'CLEANUP' => 0);
    $cscope_file->autoflush(1);
    $cscope_path = abs_path($cscope_file->filename());
    $count = 0;
    printf("recording project %s file paths in %s\n", $project, $cscope_path);
    find(\&is_code_file, $project_path);
    printf("%07d files total\n", $count);
    
    $cscope_file->flush();
    $cscope_file->close();
    my $output_path = "$output_dir/cscope.files";
    $rv = copy($cscope_path, $output_path);
    die "could not copy $cscope_path to $output_path" unless $rv;
    
    chdir($output_dir);
    my $start = time();
    my $command = "cscope -b -q -i $output_path";
    printf("cscope executing %s at %s", $command, ctime($start));
    $rv = system($command);
    my $stop = time();
    my $elapsed = $stop - $start;
    printf("cscope completed in %d secs. %03.2f mins. at %s", $elapsed, $elapsed / 60.0, ctime($stop));
    die "could not execute cscope on output $output_path" if $rv;
}

exit(0);
