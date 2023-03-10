#!/usr/bin/perl5.6.0 -w
#
# create tables (timestamped), indices, sequence, grant all to nobody.  

use lib qw( /usr/lib/perl5/site_perl/5.6.1/i686-linux/ );
use Pg;
use diagnostics;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $insertfile = "/home/postgres/work/authorperson/pgtables/insertfile.pl";

open (OUT, ">$insertfile") or die "Cannot create $insertfile : $!";
&makePGtables();
close (OUT) or die "Cannot close $insertfile : $!";

sub makePGtables {
  print OUT "#!\/usr\/bin\/perl5.6.0\n";
  print OUT "\n";
  print OUT "use lib qw( \/usr\/lib/perl5\/site_perl\/5.6.1\/i686-linux\/ );\n";
  print OUT "use Pg;\n";
  print OUT "\n";
  print OUT "\$conn = Pg::connectdb(\"dbname=testdb\");\n";
  print OUT "die \$conn->errorMessage unless PGRES_CONNECTION_OK eq \$conn->status;\n\n";

    # oneify wbg tables
#   print OUT "\$result = \$conn\->exec( \"CREATE TABLE wbg_oneified ( joinkey TEXT, wbg_oneified TEXT, wbg_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
#   print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX wbg_oneified_idx ON wbg_oneified ( joinkey )\");\n";
#   print OUT "\$result = \$conn\->exec( \"GRANT ALL ON wbg_oneified TO nobody\");\n";

    # oneify ace tables
#   print OUT "\$result = \$conn\->exec( \"CREATE TABLE ace_oneified ( joinkey TEXT, ace_oneified TEXT, ace_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
#   print OUT "\$result = \$conn\->exec( \"CREATE UNIQUE INDEX ace_oneified_idx ON ace_oneified ( joinkey )\");\n";
#   print OUT "\$result = \$conn\->exec( \"GRANT ALL ON ace_oneified TO nobody\");\n";

# one_sequence
#   print OUT "\$result = \$conn\->exec( \"CREATE SEQUENCE one_sequence \");\n";
#   print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_sequence TO nobody\");\n";

  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one ( joinkey TEXT, one INTEGER, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_groups ( joinkey TEXT, one_groups TEXT, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_firstname ( joinkey TEXT, one_firstname TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_middlename ( joinkey TEXT, one_middlename TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_lastname ( joinkey TEXT, one_lastname TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_lab ( joinkey TEXT, one_lab TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_oldlab ( joinkey TEXT, one_oldlab TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_street ( joinkey TEXT, one_street TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_city ( joinkey TEXT, one_city TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_state ( joinkey TEXT, one_state TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_post ( joinkey TEXT, one_post TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_country ( joinkey TEXT, one_country TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_email ( joinkey TEXT, one_email TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_mainphone ( joinkey TEXT, one_mainphone TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_labphone ( joinkey TEXT, one_labphone TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_officephone ( joinkey TEXT, one_officephone TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_otherphone ( joinkey TEXT, one_otherphone TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE TABLE one_fax ( joinkey TEXT, one_fax TEXT, old_timestamp TIMESTAMP, one_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP )\");\n";

  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_idx ON one ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_groups_idx ON one_groups ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_firstname_idx ON one_firstname ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_middlename_idx ON one_middlename ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_lastname_idx ON one_lastname ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_lab_idx ON one_lab ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_oldlab_idx ON one_oldlab ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_street_idx ON one_street ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_city_idx ON one_city ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_state_idx ON one_state ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_post_idx ON one_post ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_country_idx ON one_country ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_email_idx ON one_email ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_mainphone_idx ON one_mainphone ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_labphone_idx ON one_labphone ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_officephone_idx ON one_officephone ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_otherphone_idx ON one_otherphone ( joinkey )\");\n";
  print OUT "\$result = \$conn\->exec( \"CREATE INDEX one_fax_idx ON one_fax ( joinkey )\");\n";

  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_groups TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_firstname TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_middlename TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_lastname TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_lab TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_oldlab TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_street TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_city TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_state TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_post TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_country TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_email TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_mainphone TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_labphone TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_officephone TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_otherphone TO nobody\");\n";
  print OUT "\$result = \$conn\->exec( \"GRANT ALL ON one_fax TO nobody\");\n";
  print OUT "\n";
} # sub makePGtables


  # All not unique
# one sequence : 
# one_sequence		# count of created entry, used as joinkey
# one tables : 
# one_one 		# like cgc and pmid; joinkey is one#, value is # of entry
# one_groups		# which ace and wbg groups with this one
# one_firstname
# one_middlename
# one_lastname
# one_lab
# one_oldlab
# one_street
# one_city
# one_state
# one_post
# one_country
# one_email
# one_mainphone
# one_labphone
# one_officephone
# one_otherphone
# one_fax


