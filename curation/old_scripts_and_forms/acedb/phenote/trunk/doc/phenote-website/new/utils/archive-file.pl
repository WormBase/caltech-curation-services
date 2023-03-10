#!/usr/bin/perl -w
use strict;

my $dir = '.';

while (@ARGV && $ARGV[0] =~ /^\-(\S+)/) {
    my $opt = shift @ARGV;
    if ($opt eq '-h' || $opt eq '--help') {
        usage();
        exit 0;
    }
    if ($opt eq '-d' || $opt eq '--dir') {
        $dir = shift @ARGV;
    }
}

my @files = @ARGV;

my @T = localtime(time);
my $yyyy = $T[5]+1900;
my $mm = sprintf("%02d",$T[4]+1);
my $dd = sprintf("%02d",$T[3]+1);
my $datesuffix = "$yyyy-$mm-$dd";
my $ok = 1;
checkdir($yyyy);
checkdir("$yyyy/$mm");
checkdir("$yyyy/$mm/$dd");
foreach my $file (@files) {
    my @parts = split(/\//,$file);
    my $base = pop @parts;
    my $to = "$dir/$yyyy/$mm/$dd/$base.$datesuffix";
    my $cmd = "cp $file $to";
    print STDERR "Archiving: $file to $to\n";
    if (system($cmd)) {
        print STDERR "problem: $cmd\n";
        $ok=0;
    }
}
exit(!$ok);

sub checkdir {
    my $end = shift;
    my $new = "$dir/$end";
    unless (-d $new) {
        unless (mkdir($new)) {
            print STDERR "Could not create $dir\n";
            exit 1;
        }
        
    }
}


