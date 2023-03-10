#!/usr/bin/perl -w

# query pap_electronic_path for papers and check they exist at their locations  2021 01 13

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %pg;
$result = $dbh->prepare( "SELECT * FROM pap_electronic_path" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $pg{$row[0]}{$row[1]}++;
    $pg{any}{$row[1]}++;
  } # if ($row[0])
} # while (@row = $result->fetchrow)

# For papers in postgres, see if they exist at the path they point to, and print out if they do not
foreach my $paper (sort keys %pg) {
  next if ($paper eq 'any');
  foreach my $path (sort keys %{ $pg{$paper} }) {
    $path =~ s/''/'/g;
    my $good = 'bad';
    if (-e $path) { $good = 'good'; }
    if ($good eq 'bad') {
      print qq($paper\t$good\t$path\n);
    }
  } # foreach my $path (sort keys %{ $pg{$paper} })
} # foreach my $paper (sort keys %pg)

# For symlinks at web accessible URL, see if the files they target exist where they say, if they don't print out a move command to move it to a broken_symlinks directory
my %sym;
my (@syms) = </home/acedb/public_html/daniel/*>;
foreach my $sym (@syms) {
  my $target = readlink "$sym";
  if ($target) {
#     print qq(T $target T\n);

    unless (-e $target) {
#       print qq($target not in filesystem\n);
#       print qq(move $sym to temp\n);
      $sym =~ s/ /\\ /g;
      $sym =~ s/'/\\'/g;
# generate commands to move broken symlinks from where they are to a broken_symlinks directory
      print qq(mv $sym /home/acedb/public_html/daniel/broken_symlinks/\n);
    }

#     unless ($pg{any}{$target}) { 
#       print qq($target not in postgres\n);
#     }

  }
}

__END__
