#!/usr/bin/perl

my @cols = ();
my %colh = ();
my $ont;
my @onts = ();
my %onth = ();
while(<>) {
    chomp;
    next unless /./;
    s/\#\#.*//;
    if (/^ontology:\s*(.*)/i) {
        $ont = $1;
        push(@onts,$ont);
    }
    elsif (/\s+(\w+):\s+(.*)/) { # must be tag: val (space important)
        my ($k,$v) = ($1,$2);
        if (!$colh{$k}) {
            $colh{$k} = 1;
            push(@cols,$k);
        }
        $onth{$ont}->{$k} = $v;
    }
    else {
        warn($_);
    }
}

printf "%s\n",
  join("\t",
       'id',@cols);
foreach $ont (@onts) {
    printf "%s\n",
      join("\t",
           $ont,
           (map {$onth{$ont}->{$_}} @cols));
}
