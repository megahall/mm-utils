#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use File::Basename;
use Perl6::Slurp;
use Text::Markdown qw(markdown);

my $markdown = Text::Markdown->new();

sub print_header {
    my ($out) = @_;
    print $out <<EOH;
<!DOCTYPE html>
<html>
<head>
<title>Markdown Document</title>
</head>
<body>
EOH
}

sub print_footer {
    my ($out) = @_;
    print $out <<EOT;
</body>
</html>
EOT
}

foreach my $in_path (@ARGV) {
    die "invalid input path [$in_path]" unless $in_path =~ /\.md$/;

    my $out_dir  = dirname($in_path);
    my $out_file = basename($in_path, ".md") . ".html";
    my $out_path = "$out_dir/$out_file";
    #print "in_path [$in_path] out_path [$out_path]\n";

    open(my $out, ">", $out_path) or die "could not open [$out_path]";
    my $input = slurp($in_path);
    my $output = $markdown->markdown($input);
    print_header($out);
    print $out $output;
    print_footer($out);
    close($out);
}

exit(0);

