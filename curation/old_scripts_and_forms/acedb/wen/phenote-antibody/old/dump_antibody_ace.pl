#!/usr/bin/perl -w

# dump antibody phenote data for .ace upload
#
# set cronjob to : 
# 0 2 * * fri /home/postgres/work/citace_upload/antibody/dump_antibody_ace.pl
# 2009 02 03




use strict;
use diagnostics;
use Pg;

my $directory = '/home/acedb/wen/phenote-antibody/';
chdir($directory) or die "Cannot chdir to $directory : $!";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;


my %theHash;
my %names;
my @tables = qw( name summary gene clonality animal antigen peptide protein source original_publication reference remark other_name location other_animal other_antigen possible_pseudonym );

foreach my $table (@tables) {
  my $result = $conn->exec( "SELECT * FROM abp_$table ORDER BY abp_timestamp;" );
    while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      $row[2] =~ s///g;
      $theHash{$table}{$row[0]}{$row[1]}++;
      if ($table eq 'name') { push @{ $names{$row[1]} }, $row[0]; }
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
}

my $outfile = '/home/acedb/wen/phenote-antibody/antibody.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";


foreach my $name (sort keys %names) {
  next unless $name;
  print OUT "Antibody : \"$name\"\n";
  foreach my $joinkey (@{ $names{$name} } ) {
    foreach my $table (@tables) {
      next if ($table eq 'name');
      if ($theHash{$table}{$joinkey}) { 
        my $tag = ucfirst($table);
        foreach my $data (keys %{ $theHash{$table}{$joinkey} }) { 
          my @data = ();
          if ($data =~ m/ \| /) { @data = split/ \| /, $data; }
            else { push @data, $data; }
          foreach my $data (@data) {
            if ( ($tag eq 'Source') || ($tag eq 'Antigen') ) {
              print OUT "$data\n"; }
            else {
              print OUT "$tag\t\"$data\"\n"; }
          } # foreach my $data (@data)
        } # foreach my $data (keys %{ $theHash{$table}{$joinkey} }) 
      } # if ($theHash{$table}{$joinkey}) 
    } # foreach my $table (@tables)
  } # foreach my $joinkey (@{ $names{$name} } )
  print OUT "\n";
} # foreach my $name (sort keys %names)

close (OUT) or die "Cannot close $outfile : $!";
  
__END__

