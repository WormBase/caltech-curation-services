#!/usr/bin/env perl

# populate obo_name_pic_exprpattern and obo_data_pic_exprpattern. 
# this is temporary until expr pattern OA is live.  then delete these tables.
# looks like it has errors, but reads in okay  2010 10 29
#
# modified for picture_source file for Daniela.  Populate one per line, joinkey and picturesource .jpg file, 
# so that there will be multiple entries per joinkey, so that when creating term info it works like synonyms
# or PDFs.  2010 11 15
#
# modified for new format of  picture_source  which has <folder>\t<filename(.jpg|.txt)>  2010 12 06
#
# joinkey of obo_data_pic_picturesource is either WBPaper######## or WBPerson### now.  2010 12 08
#
# added code for new obotables, need to delete code for old tables when live.  2011 02 23
#
# added url accession code from third column.  2011 03 02
#
# allow .html extension in files.  2011 07 15
#
# got rid of obo_data_pic_picturesource  2011 07 21
#
# all the pictures got moved to http://caltech.wormbase.org/~daniela/all_pictures/ OICR/ now has curated pictures.  2012 10 19
#
# dockerized.  when going live will need to transfer /home/acedb/draciti/picture_source/picture_source 
# to  /usr/caltech_curation_files/daniela/picture_source/picture_source  2023 03 14
#
# 0 2 * * * /usr/lib/scripts/pgpopulation/pic_picture/picture_source/populate_obo_data_pic_picturesource.pl



use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Dotenv -load => '/usr/lib/.env';

my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my @pgcommands;
# push @pgcommands, "DELETE FROM obo_name_pic_picturesource ;";
# push @pgcommands, "DELETE FROM obo_data_pic_picturesource ;";
push @pgcommands, "DELETE FROM obo_data_picturesource ;";

# my $directory = '/home/acedb/draciti/picture_source/';
# chdir($directory) or die "Cannot chdir to $directory : $!";

# $/ = "";
my %hash;
# my $infile = 'picture_source';
my $infile = $ENV{CALTECH_CURATION_FILES_INTERNAL_PATH} . '/daniela/picture_source/picture_source';
open (IN, "<$infile") or die "Cannot open $infile : $!";
while (my $line = <IN>) {
  chomp $line;
  $line =~ s/\'/''/g; 
  my ($paper, $filename, $urlaccession) = split/\t/, $line;
  if ($line =~ m/\.jpg$/) { 
#     my $url = 'http://caltech.wormbase.org/daniela/OICR/Pictures/' . $paper . '/' . $filename;
    my $url = 'http://caltech.wormbase.org/~daniela/all_pictures/' . $paper . '/' . $filename;
    my $data = 'jpg_picture_source: <a href="' . $url . '" target="new">' . $filename . '</a>';
    $hash{$paper}{$data}++; }
  elsif ( ($line =~ m/\.html$/) || ($line =~ m/\.html$/) || ($line =~ m/\.txt$/) || ($line =~ m/\.txt\t/) ) {
#     my $url = 'http://caltech.wormbase.org/daniela/OICR/Pictures/' . $paper . '/' . $filename;
    my $url = 'http://caltech.wormbase.org/~daniela/all_pictures/' . $paper . '/' . $filename;
    my $data = 'txt_picture_source: <a href="' . $url . '" target="new">' . $filename . '</a>';
    if ($urlaccession) { $data .= " $urlaccession"; }
    $hash{$paper}{$data}++; }
  else { print "ERROR not a valid line $line\n"; }
#     push @pgcommands, "INSERT INTO obo_data_pic_picturesource VALUES ( '$joinkey', '$line' );"; } }
#   my ($header) = shift @lines;
#   my ($joinkey) = $header =~ m/WBPaper(\d+):/;
#   foreach my $line (@lines) { if ($line =~ m/\.jpg$/) { $line =~ s/\'/''/g; 
#     push @pgcommands, "INSERT INTO obo_data_pic_picturesource VALUES ( '$joinkey', '$line' );"; } }
#   my @data ;
#   foreach my $line (@lines) { if ($line =~ m/\.jpg$/) { push @data, "picture_source: $line"; } } 
#   my $data = join"\n", @data;
#   $data =~ s/\'/''/g;
#   push @pgcommands, "INSERT INTO obo_data_pic_picturesource VALUES ( '$joinkey', '$data' );";
} # while (my $para = <IN>)
close (IN) or die "Cannot close $infile : $!";
$/ = "\n";

foreach my $paper (sort keys %hash) {
  my $joinkey = '';
  if ($paper =~ m/(WBPaper\d+)/) { $joinkey = $1; }
    elsif ($paper =~ m/(WBPerson\d+)/) { $joinkey = $1; }
    else { next; }						# not a correct entry
  my (@data) = sort keys %{ $hash{$paper} };
  if ($data[0]) {
    my $data = join"\n", @data; 
    push @pgcommands, "INSERT INTO obo_data_picturesource VALUES ( '$joinkey', E'$data' );";
#     push @pgcommands, "INSERT INTO obo_data_pic_picturesource VALUES ( '$joinkey', '$data' );";	# DELETE this when new OA is live
  }
} # foreach my $paper (sort keys %hash)

foreach my $command (@pgcommands) {
#   print "$command\n";
# UNCOMMENT TO POPULATE, looks like it has errors, but reads in okay  2010 10 29
  my $result = $dbh->do( $command );
}


__END__

