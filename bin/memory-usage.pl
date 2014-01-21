#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Fcntl;
use File::Path qw(make_path);
use Format::Human::Bytes;
use Getopt::Std;
use IO::Handle;
use List::Util qw(max min sum);
#use Math::Derivative qw(Derivative1);
use Number::Format;
use POSIX qw(_exit strftime);
use Proc::ProcessTable;
use Sys::CPU;
use Sys::MemInfo;
use Time::HiRes qw(gettimeofday);

$Data::Dumper::Indent   = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Terse    = 1;

my $verbose = 0;

my $seconds;
my $microseconds;
my $time;
my $time_human;
my $s = {};

time_update();

my $HOME = $ENV{"HOME"};
# do not try to catch an error from make_path
# it returns 0 when the directory exists already
make_path("$HOME/memory-usage");
my $path = sprintf("%s/memory-usage/memory-usage-log-%06d.txt", $ENV{"HOME"}, $$);
sysopen(my $log_file, $path, O_CREAT | O_WRONLY | O_APPEND | O_TRUNC) || die "failed opening log file: $!";
$log_file->autoflush(1);
STDOUT->autoflush(1);

sub time_update {
    ($seconds, $microseconds) = gettimeofday();
    $time = $seconds + $microseconds / 1_000_000.0;
    $time_human = strftime("%Y-%m-%d %H:%M:%S", localtime($seconds)) . sprintf(".%06d", $microseconds);
    return $time;
}

sub clog {
    my ($message) = @_;
    
    my $log = "[$time_human] pid [$$] $message";
    print $log;
    syswrite($log_file, $log);
}

sub handle_signals {
    my ($sig_name) = @_;
    
    clog "handling signal [SIG$sig_name] and dumping statistics...\n" . Dumper($s) if keys(%$s);
    
    if ($sig_name =~ m/HUP|INT|QUIT|TERM/i) {
        clog "exiting due to signal [SIG$sig_name]\n";
        _exit(0);
    }
}

sub linear_derivative {
    my ($x1, $y1, $x2, $y2) = @_;
    return ($x2 - $x1) ? ($y2 - $y1) / ($x2 - $x1) : 0.0;
}

$SIG{'HUP'} = \&handle_signals;
$SIG{'INT'} = \&handle_signals;
$SIG{'QUIT'} = \&handle_signals;
$SIG{'TERM'} = \&handle_signals;
$SIG{'USR1'} = \&handle_signals;
$SIG{'USR2'} = \&handle_signals;

$Getopt::Std::STANDARD_HELP_VERSION = 1;

sub main::HELP_MESSAGE {
    my ($fh, $name, $version, $bad_options) = @_;
    print $fh "Usage: $0 ...\n";
    print $fh "    [-c] [display CPU data]\n";
    print $fh "    [-n process name]\n";
    print $fh "    [-p process ID]\n";
    print $fh "    [-v] [verbose mode]\n";
    exit(1);
}

sub main::VERSION_MESSAGE {
    my ($fh, $name, $version, $bad_options) = @_;
    print $fh "memory-usage.pl 0.0.1\n";
    print $fh "Copyright (C) 2012 Spirent Communications\n";
}

my $options = {};
my $options_ok = getopts("n:p:v", $options);

die "invalid options provided" unless $options_ok;

my $cpu_data = $options->{'c'} // 0;
my $name     = $options->{'n'};
my $pid      = $options->{'p'};

die "must specify only name or pid" unless $name xor $pid;

clog "starting memory-usage.pl...\n";

my $ps = Proc::ProcessTable->new('cache_ttys' => 0);
my $fn = Number::Format->new();
my $fb = Format::Human::Bytes->new();
my $max_cpu_load = $fn->format_number(Sys::CPU::cpu_count() * 100.0, 0) . "%";
my @old_pids;
my @new_pids;

while (1) {
    time_update();
    my $pids = {};
    my @memory = ();
    my @cpu    = ();
    
    foreach my $p (@{$ps->table}) {
        next if $name && $p->fname !~ m/.*$name.*/i;
        next if $pid && $p->pid != $pid;
        clog "process: " . Dumper($p) if $verbose;
        
        $pids->{$p->pid} = 1;
        push(@memory, $p->rss);
        push(@cpu,    $p->pctcpu);
    }
    goto retry unless scalar(%$pids) && @memory;
    
    @new_pids = sort { $a <=> $b } (keys(%$pids));
    clog "pids: " . join(', ', keys(%$pids)) . " old_pids: " . join(', ', @new_pids) . " new_pids: " . join(', ', @new_pids) . "\n" if $verbose;
    my $id = $name || $pid;
    unless (@old_pids ~~ @new_pids) {
        clog "$id pid list changed to " . join(' ', keys(%$pids)) . ", resetting statistics...\n";
        handle_signals("USR1");
        $s = {};
    }
    @old_pids = @new_pids;
    
    $s->{'program'} ||= 0;
    $s->{'program_old'} ||= 0;
    $s->{'program'} = sum(@memory);
    $s->{'program_bytes'} = $fn->format_number($s->{'program'});
    $s->{'program_human'} = $fb->base2($s->{'program'}, 3);
    
    $s->{'program_run'} ||= 0;
    $s->{'program_run'}++;
    $s->{'program_run'} = 1 if $s->{'program'} != $s->{'program_old'};
    $s->{'program_old'} = $s->{'program'};
    
    $s->{'program_min'} ||= 0;
    $s->{'program_max'} ||= 0;
    
    $s->{'program_max_old'} ||= 0;
    $s->{'program_max_run'} ||= 0;
    
    if ($s->{'program'} >= $s->{'program_max'}) {
        $s->{'program_max'} = $s->{'program'};
        
        $s->{'program_max_bytes'} = $fn->format_number($s->{'program_max'});
        $s->{'program_max_human'} = $fb->base2($s->{'program_max'}, 3);
        
        $s->{'program_max_run'} = 1;
        $s->{'program_max_old'} = $s->{'program_max'};
    }
    else {
        $s->{'program_max_run'}++;
    }
    
    $s->{'sys_free'} = $fb->base2(Sys::MemInfo::get('freemem'), 3);
    $s->{'sys_swap'} = $fb->base2(Sys::MemInfo::get('totalswap') - Sys::MemInfo::get('freeswap'), 3);
    $s->{'sys_swap'} = '0.000B' if $s->{'sys_swap'} eq '0.000';

    $s->{'cpu'}           = sum(@cpu) || 0.0;
    $s->{'cpu_old'}     ||= 0;
    $s->{'cpu_run'}++;
    $s->{'cpu_run'}       = 1 if $s->{'cpu'} != $s->{'cpu_old'};
    $s->{'cpu_old'}       = $s->{'cpu'};
    $s->{'cpu_max'}     ||= 0.0;
    $s->{'cpu_max'}       = max($s->{'cpu'}, $s->{'cpu_max'});
    
    $s->{'cpu_human'}     = $fn->format_number($s->{'cpu'}, 3, 1) . "%";
    $s->{'cpu_max_human'} = $fn->format_number($s->{'cpu_max'},   3, 1) . "%";
    
    my $message = sprintf("pgm %16s b, %11s r %5s; max %16s b, %11s, r %5s; sys f %11s s %11s;%s",
        $s->{'program_bytes'}, $s->{'program_human'}, $s->{'program_run'} . "",
        $s->{'program_max_bytes'},   $s->{'program_max_human'},   $s->{'program_max_run'} . "",
        $s->{'sys_free'}, $s->{'sys_swap'}, $cpu_data? " " : "\n");
    
    $message .= sprintf("cpu %8s r %5s; max %9s / %5s\n",
        $s->{'cpu_human'}, $s->{'cpu_run'}, $s->{'cpu_max_human'}, $max_cpu_load) if $cpu_data;
    
    clog $message;
    
    retry:
    sleep(1);
}

exit(0);
