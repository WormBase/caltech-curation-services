#!/usr/bin/perl -w


use strict;
use diagnostics;
use DBI;
use Jex;		# filter for Pg

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

my $result;


  my @subtables = qw( lastname firstname firstinit collectivename standardname orcid affiliation rank );

  foreach my $type (@subtables) {
    $result = $dbh->do( "DROP TABLE h_pap_author_$type" );
    $result = $dbh->do( "DROP TABLE pap_author_$type" );

    my $papt = 'pap_author_' . $type;
    $result = $dbh->do( "CREATE TABLE $papt ( author_id text, $papt text, pap_join integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone)" ); 
    $result = $dbh->do( "CREATE INDEX ${papt}_idx ON $papt USING btree (author_id);" );
    $result = $dbh->do( "REVOKE ALL ON TABLE $papt FROM PUBLIC;" );
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO postgres;" );
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO acedb;" );
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO apache;" );
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO \"www-data\";" );
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO azurebrd;" );
    $result = $dbh->do( "GRANT ALL ON TABLE $papt TO cecilia;" );
    
    $result = $dbh->do( "CREATE TABLE h_$papt ( author_id text, $papt text, pap_join integer, pap_curator text, pap_timestamp timestamp with time zone DEFAULT ('now'::text)::timestamp without time zone)" ); 
    $result = $dbh->do( "CREATE INDEX h_${papt}_idx ON $papt USING btree (author_id);" );
    $result = $dbh->do( "REVOKE ALL ON TABLE h_$papt FROM PUBLIC;" );
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO postgres;" );
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO acedb;" );
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO apache;" );
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO \"www-data\";" );
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO azurebrd;" );
    $result = $dbh->do( "GRANT ALL ON TABLE h_$papt TO cecilia;" );

  }
