#!/usr/bin/perl -w
#
# Quick PG query to get some data (about gene function and new mutant) for Andrei  2002 02 04

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $outfile = "reupdatepapauthor.pl";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

print OUT <<"EndOfText";
#!/usr/bin/perl -w

use diagnostics;
use Pg;

my \$conn = Pg::connectdb("dbname=testdb");
die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;

EndOfText

my $result = $conn->exec( "SELECT * FROM pap_author WHERE pap_person IS NOT NULL;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    $row[3] =~ s///g;
    $row[4] =~ s///g;
    $row[5] =~ s///g;
    my $joinkey = $row[0];
    my $author = $row[1];
    print "$row[0]\t$row[1]\t$row[2]\t$row[3]\t$row[4]\t$row[5]\n";
    print OUT "\$result = \$conn->exec( \"UPDATE pap_author SET pap_timestamp = \\\'$row[5]\\\' WHERE joinkey = \\\'$joinkey\\\' AND pap_author = \\\'$author\\\'; \" );\n";
    print OUT "\$result = \$conn->exec( \"UPDATE pap_author SET pap_person = \\\'$row[2]\\\' WHERE joinkey = \\\'$joinkey\\\' AND pap_author = \\\'$author\\\'; \" );\n\n";
#     print OUT "STRUCTURE CORRECTION\t$row[0]\t$row[1]\t$row[2]\n\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

close (OUT) or die "Cannot close $outfile : $!";
