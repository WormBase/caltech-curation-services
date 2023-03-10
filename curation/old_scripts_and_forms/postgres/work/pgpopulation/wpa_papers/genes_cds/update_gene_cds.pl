#!/usr/bin/perl

# Superceded by the more recent update2_gene_cds.pl in 2006 06 13
# Last updated 2006 06 08



use strict;
use LWP::Simple;
use Jex;
use diagnostics;
use LWP::UserAgent;					# not in use
use Ace;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my %words;		# words and their corresponding genes

my $date = &getSimpleSecDate();

my $directory = '/home/azurebrd/public_html/sanger/genes_cds';

chdir($directory) or die "Cannot go to $directory ($!)";


$|=9;   #turn off output caching

if ($#ARGV != 0) {
    print "usage: $0 out\n";
    exit;
}


open OUT, ">$ARGV[0]" || die "cannot open $ARGV[1] :$!\n";


print "Connecting to database...";

my $db = Ace->connect('sace://aceserver.cshl.org:2005') || die "Connection failure: ", Ace->error;
# my $db = Ace->connect(-path => '/home/igor/AceDB',  -program => '/home/igor/AceDB/bin/tace') || die print "Connection failure: ", Ace->error;

print "done\n";




my $query="find gene live AND species=\"*elegans\"";
my @genes=$db->find($query);

print scalar @genes, " live C. elegans genes found\n";

my $i=0;
my $j=0;
foreach (@genes) {
    $i++;
    if ($i % 1000 == 0) {
        print "$i genes processed\n";
    }
    
    my @names=();
    push @names, $_->CGC_name;
    push @names, $_->Sequence_name;
    push @names, $_->Molecular_name;
    push @names, $_->Other_name;
    my %name_hash=();
    foreach my $n (@names) {
        $name_hash{$n}=1;
    }
    foreach my $k (keys %name_hash) {
        push @{ $words{$k} }, $_;
        print OUT "$_\t$k\n";
        $j++;
    }
}

print "$i genes processed\n";
print "$j records generated\n";

my %abstracts;
my $result = $conn->exec( "SELECT * FROM wpa_abstract ORDER BY wpa_timestamp" );
while (my @row = $result->fetchrow) {
  if ($row[3] eq 'valid') { $abstracts{$row[0]} = $row[1]; }
    else { delete $abstracts{$row[0]}; }
} # while (my @row = $result->fetchrow)

my $count = 0;
foreach my $abs_join (sort keys %abstracts) {
  my %filtered_loci;
  $count++;
  last if ($count > 10);
  my $abstract = $abstracts{$abs_join};
  my (@words) = split/\s+/, $abstract;
  foreach my $word (@words) {
    if ($words{$word}) { $filtered_loci{$word}++; } }
  foreach my $word (sort keys %filtered_loci) {
    print OUT "$abs_join\t$word\n";
  }
}

