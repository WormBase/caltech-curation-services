#!/usr/bin/perl -w

# dump antibody phenote data for .ace upload
#
# update dumper to strip leading and trailing ".  split on ","  
# for Wen and Xiaodong   2010 09 30
#
# changed tables from abp_reference to abp_paper ;  abp_location to abp_laboratory ;
# changed .ace tags to match model.  2011 05 22
# 
# 0 2 * * fri /home/postgres/work/citace_upload/antibody/dump_antibody_ace.pl
# 2009 02 03
#
# moved cronjob to acedb account
# 0 2 * * thu /home/acedb/xiaodong/oa_antibody_dumper/dump_antibody_ace.pl
# 2011 06 05


# set cronjob to :
# 0 2 * * thu /home/acedb/xiaodong/oa_antibody_dumper/dump_antibody_ace.pl





use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

my $directory = '/home/postgres/work/citace_upload/antibody/';
chdir($directory) or die "Cannot chdir to $directory : $!";


my %theHash;
my %names;
my @tables = qw( name summary gene clonality animal antigen peptide protein source original_publication paper remark other_name laboratory other_animal other_antigen possible_pseudonym );

foreach my $table (@tables) {
  my $result = $dbh->prepare( "SELECT * FROM abp_$table ORDER BY abp_timestamp;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g;
      $row[1] =~ s///g;
      $row[2] =~ s///g;
      my @objects;
      if ($row[1] =~ m/^\"/) { $row[1] =~ s/^\"//; }
      if ($row[1] =~ m/\"$/) { $row[1] =~ s/\"$//; }
      if ($row[1] =~ m/","/) { 
          (@objects) = split/\",\"/, $row[1]; }
        else { push @objects, $row[1]; }
      foreach my $object (@objects) {
        $theHash{$table}{$row[0]}{$object}++;
      } # foreach my $object (@objects)
      if ($table eq 'name') { push @{ $names{$row[1]} }, $row[0]; }
    } # if ($row[0])
  } # while (@row = $result->fetchrow)
}

my $outfile = '/home/postgres/public_html/cgi-bin/data/antibody.ace';
open (OUT, ">$outfile") or die "Cannot create $outfile : $!";


foreach my $name (sort keys %names) {
  next unless $name;
  print OUT "Antibody : \"$name\"\n";
  foreach my $joinkey (@{ $names{$name} } ) {
    foreach my $table (@tables) {
      next if ($table eq 'name');
      if ($theHash{$table}{$joinkey}) { 
        my $tag = ucfirst($table);
        if ($tag eq 'Laboratory') { $tag = 'Location'; }
        if ($tag eq 'Paper') { $tag = 'Reference'; }
        foreach my $data (keys %{ $theHash{$table}{$joinkey} }) { 
          my @data = ();
          if ($data =~ m/ \| /) { @data = split/ \| /, $data; }
            else { push @data, $data; }
          foreach my $data (@data) {
            next unless ($data);	# skip stuff without data  2009 03 27
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

