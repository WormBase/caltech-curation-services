#!/usr/bin/perl -w

# to test creating a view across cur_svmdata and cur_nncdata  2021 01 20


use strict;
use diagnostics;
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

# put postgres users that should have 'all' access to the table.
my @users_all = ('apache', 'azurebrd', 'cecilia', '"www-data"');

# put postgres users that should have 'select' access to the table.  mainly so they can log on and see the data from a shell, but would probably work if you set the webserver to have select access, it would just give error messages if someone tried to update data.
my @users_select = ('acedb');


  my $table = 'test_nnc';
  $result = $dbh->do( "DROP TABLE $table;" );
  $result = $dbh->do( "CREATE TABLE $table (
                         cur_paper text, 
                         cur_datatype text, 
                         cur_date text, 
                         $table text, 
                         cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE $table FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE $table TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE $table TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${table}_datatype_idx ON $table USING btree (cur_datatype); ");
  $result = $dbh->do( "CREATE INDEX ${table}_paper_idx ON $table USING btree (cur_paper); ");

  my $table = 'test_nnd';
  $result = $dbh->do( "DROP TABLE $table;" );
  $result = $dbh->do( "CREATE TABLE $table (
                         cur_paper text, 
                         cur_datatype text, 
                         cur_date text, 
                         $table text, 
                         cur_version text, 
                         cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE $table FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE $table TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE $table TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${table}_datatype_idx ON $table USING btree (cur_datatype); ");
  $result = $dbh->do( "CREATE INDEX ${table}_paper_idx ON $table USING btree (cur_paper); ");

  $table = 'test_svm';
  $result = $dbh->do( "DROP TABLE $table;" );
  $result = $dbh->do( "CREATE TABLE $table (
                         cur_paper text, 
                         cur_datatype text, 
                         cur_date text, 
                         $table text, 
                         cur_version text, 
                         cur_timestamp timestamp with time zone DEFAULT \"timestamp\"('now'::text)); " );
  $result = $dbh->do( "REVOKE ALL ON TABLE $table FROM PUBLIC; ");
  foreach my $user (@users_select) { 
    $result = $dbh->do( "GRANT SELECT ON TABLE $table TO $user; "); }
  foreach my $user (@users_all) { 
    $result = $dbh->do( "GRANT ALL ON TABLE $table TO $user; "); }
  $result = $dbh->do( "CREATE INDEX ${table}_datatype_idx ON $table USING btree (cur_datatype); ");
  $result = $dbh->do( "CREATE INDEX ${table}_paper_idx ON $table USING btree (cur_paper); ");

__END__


SELECT * FROM test_nnc UNION SELECT * FROM test_svm;
SELECT * FROM test_nnd UNION SELECT * FROM test_svm;

SELECT * FROM test_nnd WHERE cur_paper = '00000003' UNION SELECT * FROM test_svm WHERE cur_paper = '00000003' ;

SELECT cur_paper, cur_datatype, cur_date, test_nnc, NULL as cur_version, cur_timestamp FROM  test_nnc UNION SELECT * FROM test_svm;

CREATE VIEW cur_blackbox AS
  SELECT cur_paper, cur_datatype, cur_date, cur_nncdata, NULL as cur_version, cur_timestamp FROM cur_nncdata UNION SELECT * FROM cur_svmdata;



INSERT INTO test_nnc VALUES('00000003', 'antibody', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'catalyticact', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'expression_cluster', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'geneint', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'geneprod', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'genereg', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'genesymbol', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'humandisease', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'newmutant', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'otherexpr', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'overexpr', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'rnai', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'seqchange', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'structcorr', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000003', 'transporter', '20201224', 'HIGH');
INSERT INTO test_nnc VALUES('00000006', 'geneprod', '20201224', 'LOW');
INSERT INTO test_nnc VALUES('00000006', 'genereg', '20201224', 'LOW');
INSERT INTO test_nnc VALUES('00000006', 'genesymbol', '20201224', 'LOW');
INSERT INTO test_nnc VALUES('00000006', 'structcorr', '20201224', 'MEDIUM');
INSERT INTO test_nnc VALUES('00000006', 'transporter', '20201224', 'LOW');
INSERT INTO test_nnc VALUES('00000008', 'geneprod', '20201224', 'LOW');
INSERT INTO test_nnc VALUES('00000008', 'genesymbol', '20201224', 'LOW');
INSERT INTO test_nnc VALUES('00000008', 'humandisease', '20201224', 'LOW');
INSERT INTO test_nnc VALUES('00000008', 'newmutant', '20201224', 'MEDIUM');
INSERT INTO test_nnc VALUES('00000008', 'seqchange', '20201224', 'LOW');
INSERT INTO test_nnc VALUES('00000008', 'structcorr', '20201224', 'LOW');

INSERT INTO test_nnd VALUES('00000003', 'antibody', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'catalyticact', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'expression_cluster', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'geneint', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'geneprod', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'genereg', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'genesymbol', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'humandisease', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'newmutant', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'otherexpr', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'overexpr', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'rnai', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'seqchange', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'structcorr', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000003', 'transporter', '20201224', 'HIGH', '1');
INSERT INTO test_nnd VALUES('00000006', 'geneprod', '20201224', 'LOW', '1');
INSERT INTO test_nnd VALUES('00000006', 'genereg', '20201224', 'LOW', '1');
INSERT INTO test_nnd VALUES('00000006', 'genesymbol', '20201224', 'LOW', '1');
INSERT INTO test_nnd VALUES('00000006', 'structcorr', '20201224', 'MEDIUM', '1');
INSERT INTO test_nnd VALUES('00000006', 'transporter', '20201224', 'LOW', '1');
INSERT INTO test_nnd VALUES('00000008', 'geneprod', '20201224', 'LOW', '1');
INSERT INTO test_nnd VALUES('00000008', 'genesymbol', '20201224', 'LOW', '1');
INSERT INTO test_nnd VALUES('00000008', 'humandisease', '20201224', 'LOW', '1');
INSERT INTO test_nnd VALUES('00000008', 'newmutant', '20201224', 'MEDIUM', '1');
INSERT INTO test_nnd VALUES('00000008', 'seqchange', '20201224', 'LOW', '1');
INSERT INTO test_nnd VALUES('00000008', 'structcorr', '20201224', 'LOW', '1');

INSERT INTO test_svm VALUES('00000003', 'antibody', '20121210', 'NEG','1','2013-01-14 12:36:17.874673-08');
INSERT INTO test_svm VALUES('00000003', 'geneint', '20121210', 'NEG','1','2013-01-14 12:36:17.907079-08');
INSERT INTO test_svm VALUES('00000003', 'geneprod', '20121210', 'NEG','1','2013-01-14 12:36:17.915283-08');
INSERT INTO test_svm VALUES('00000003', 'genereg', '20121210', 'NEG','1','2013-01-14 12:36:17.923712-08');
INSERT INTO test_svm VALUES('00000003', 'newmutant', '20121210', 'NEG','1','2013-01-14 12:36:17.934968-08');
INSERT INTO test_svm VALUES('00000003', 'otherexpr', '20121210', 'NEG','1','2013-01-14 12:36:17.943705-08');
INSERT INTO test_svm VALUES('00000003', 'overexpr', '20121210', 'NEG','1','2013-01-14 12:36:17.954961-08');
INSERT INTO test_svm VALUES('00000003', 'rnai', '20121210', 'NEG','1','2013-01-14 12:36:17.974958-08');
INSERT INTO test_svm VALUES('00000003', 'seqchange', '20121210', 'NEG','1','2013-01-14 12:36:17.983718-08');
INSERT INTO test_svm VALUES('00000003', 'structcorr', '20121210', 'NEG','1','2013-01-14 12:36:17.994962-08');
INSERT INTO test_svm VALUES('00000003', 'catalyticact', '20150210', 'NEG','1','2015-02-20 04:00:02.90533-08');
INSERT INTO test_svm VALUES('00000006', 'antibody', '20121210', 'NEG','1','2013-01-14 12:36:18.013723-08');
INSERT INTO test_svm VALUES('00000006', 'geneint', '20121210', 'NEG','1','2013-01-14 12:36:18.029736-08');
INSERT INTO test_svm VALUES('00000006', 'geneprod', '20121210', 'NEG','1','2013-01-14 12:36:18.040291-08');
INSERT INTO test_svm VALUES('00000006', 'genereg', '20121210', 'NEG','1','2013-01-14 12:36:18.048619-08');
INSERT INTO test_svm VALUES('00000006', 'newmutant', '20121210', 'NEG','1','2013-01-14 12:36:18.063711-08');
INSERT INTO test_svm VALUES('00000006', 'otherexpr', '20121210', 'NEG','1','2013-01-14 12:36:18.078808-08');
INSERT INTO test_svm VALUES('00000006', 'overexpr', '20121210', 'NEG','1','2013-01-14 12:36:18.093712-08');
INSERT INTO test_svm VALUES('00000006', 'rnai', '20121210', 'NEG','1','2013-01-14 12:36:18.113708-08');
INSERT INTO test_svm VALUES('00000006', 'seqchange', '20121210', 'NEG','1','2013-01-14 12:36:18.123775-08');
INSERT INTO test_svm VALUES('00000006', 'structcorr', '20121210', 'NEG','1','2013-01-14 12:36:18.134969-08');
INSERT INTO test_svm VALUES('00000006', 'catalyticact', '20150210', 'NEG','1','2015-02-20 04:00:02.909343-08');
INSERT INTO test_svm VALUES('00000008', 'antibody', '20121210', 'NEG','1','2013-01-14 12:36:18.153715-08');
INSERT INTO test_svm VALUES('00000008', 'geneint', '20121210', 'NEG','1','2013-01-14 12:36:18.16372-08');
INSERT INTO test_svm VALUES('00000008', 'geneprod', '20121210', 'NEG','1','2013-01-14 12:36:18.176961-08');
INSERT INTO test_svm VALUES('00000008', 'genereg', '20121210', 'NEG','1','2013-01-14 12:36:18.184968-08');
INSERT INTO test_svm VALUES('00000008', 'newmutant', '20121210', 'low','1','2013-01-14 12:36:18.203716-08');
INSERT INTO test_svm VALUES('00000008', 'otherexpr', '20121210', 'NEG','1','2013-01-14 12:36:18.223711-08');
INSERT INTO test_svm VALUES('00000008', 'overexpr', '20121210', 'NEG','1','2013-01-14 12:36:18.272001-08');
INSERT INTO test_svm VALUES('00000008', 'rnai', '20121210', 'NEG','1','2013-01-14 12:36:18.315344-08');
INSERT INTO test_svm VALUES('00000008', 'seqchange', '20121210', 'high','1','2013-01-14 12:36:18.323769-08');
INSERT INTO test_svm VALUES('00000008', 'structcorr', '20121210', 'NEG','1','2013-01-14 12:36:18.334963-08');
INSERT INTO test_svm VALUES('00000008', 'catalyticact', '20150210', 'NEG','1','2015-02-20 04:00:02.911556-08');


INSERT INTO cur_nncdata VALUES ('00000124', 'antibody',  'two1823' , 'positive', '2',  'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00000124', 'antibody',  'two1'    , 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00000123', 'antibody',  'two1'    , 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00030869', 'antibody',  'two1'    , 'positive', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00000003', 'antibody',  'two1'    , 'positive', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00004558', 'antibody',  'two1'    , 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00004568', 'antibody',  'two1'    , 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00041460', 'otherexpr', 'two12028', 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00000072', 'otherexpr', 'two12028', 'positive', '1',  'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00000566', 'otherexpr', 'two12028', 'positive', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00000599', 'otherexpr', 'two12028', 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');
INSERT INTO cur_nncdata VALUES ('00000633', 'otherexpr', 'two12028', 'negative', NULL, 'some long comment goes here for soe reason blah blah blah blah 1234 asdf m01234');

