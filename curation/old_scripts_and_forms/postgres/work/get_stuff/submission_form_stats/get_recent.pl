#!/usr/bin/perl -w

# get stats from user submissions  for Karen  2008 03 06

use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my $from_date = '2007-09-06';

my $result = $conn->exec( "SELECT COUNT(*) FROM tpd_mapper WHERE tpd_timestamp > '$from_date';" );
my @row = $result->fetchrow;
print "2_pt_data.cgi	$row[0] entries since $from_date\n";

$result = $conn->exec( "SELECT COUNT(*) FROM ale_submitter_email WHERE ale_timestamp > '$from_date';" );
@row = $result->fetchrow;
print "allele.cgi	$row[0] entries since $from_date\n";

print "author.cgi	Not a curator-created class anymore, no data since 2005 02 05\n";

$result = $conn->exec( "SELECT COUNT(*) FROM bre_ip WHERE bre_timestamp > '$from_date';" );
@row = $result->fetchrow;
print "breakpoint.cgi	$row[0] entries since $from_date\n";

$result = $conn->exec( "SELECT COUNT(*) FROM wpa_author_verified WHERE wpa_timestamp > '$from_date';" );
@row = $result->fetchrow;
print "confirm_paper.cgi	$row[0] entries since $from_date\n";

$result = $conn->exec( "SELECT COUNT(*) FROM dfd_ip WHERE dfd_timestamp > '$from_date';" );
@row = $result->fetchrow;
print "df_dp.cgi	$row[0] entries since $from_date\n";

print "expr_patter.cgi	Not stored in postgres, emailed directly to Wen\n";

$result = $conn->exec( "SELECT COUNT(*) FROM ggn_ip WHERE ggn_timestamp > '$from_date';" );
@row = $result->fetchrow;
print "gene_name.cgi	$row[0] entries since $from_date\n";

print "go_gene.cgi	Not stored in postgres, emailed directly to Ranjana and Kimberly\n";

$result = $conn->exec( "SELECT COUNT(*) FROM mul_ip WHERE mul_timestamp > '$from_date';" );
@row = $result->fetchrow;
print "multi_pt.cgi	$row[0] entries since $from_date\n";

print "person.cgi	Not stored in postgres, emailed directly to Cecilia\n";
print "person_lineage.cgi	Directly changes curation data in postgres, individual submissions not counted and emailed directly to Cecilia\n";

$result = $conn->exec( "SELECT COUNT(*) FROM rea_ip WHERE rea_timestamp > '$from_date';" );
@row = $result->fetchrow;
print "rearrangement.cgi	$row[0] entries since $from_date\n";

print "rnai.cgi	Not stored in postgres, emailed directly to Raymond\n";
print "transgene.cgi	Not stored in postgres, emailed directly to Wen\n";
