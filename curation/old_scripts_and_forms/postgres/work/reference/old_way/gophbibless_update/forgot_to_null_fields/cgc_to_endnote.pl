#!/usr/bin/perl -w

# forgot to add nulls for all the paper copy related things.  added here.  2002 03 07

$insertfile = "insertfile_forgot_null.pl";

open (INS, ">$insertfile") || die "Couldn't create PG file $insertfile.  $!\n";

print INS "#!\/usr\/bin\/perl5.6.0\n";
print INS "\n";
print INS "use lib qw( \/usr\/lib/perl5\/site_perl\/5.6.1\/i686-linux\/ );\n";
print INS "use Pg;\n";
print INS "\n";
print INS "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
print INS "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;\n\n";

for (my $i = 4969; $i < 5107; $i++) {
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_pdf VALUES (\'cgc$i\', NULL)\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_lib VALUES (\'cgc$i\', NULL)\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_html VALUES (\'cgc$i\', NULL)\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_tif VALUES (\'cgc$i\', NULL)\");\n";
  print INS "\$result = \$conn\->exec( \"INSERT INTO ref_hardcopy VALUES (\'cgc$i\', NULL)\");\n";
} # for (my $i = 4969; $i < 5107; $i++) 
