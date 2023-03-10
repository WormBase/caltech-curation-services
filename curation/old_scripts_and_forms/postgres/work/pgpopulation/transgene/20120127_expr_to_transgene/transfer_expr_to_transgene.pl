#!/usr/bin/perl -w

# transfer expr data to transgene OA 2012 01 28

# get mapping of transgene publicname/synonym to transgene ID.  if an expr object with reportergene and without transgene exists, 
# get exprname_Ex to transgene ID mapping, and create the exp_transgene and remove the exp_reportergene.  If the transgene mapping
# does not already exist, create a new transgene object and then assign exp_transgene and remove exp_reportergene.  2012 08 27
#
# live on tazendra 2012 09 06
#
# was adding the exp_name to  %trpNameToId  instead of the _Ex synonym, so transgenes were being created once for each pgid for a 
# given exp_name.  2013 08 16



use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 
my $result;

my %data;
my $pgid = &getHighestPgid();
my %trpNameToId;
my %expr_authors;
my %auth_to_per;
my %bad_authors;

&readExprAce();
&populateTrpNameToId();

# $result = $dbh->prepare( "SELECT exp_name.exp_name, exp_reportergene.exp_reportergene, exp_paper.exp_paper FROM exp_name, exp_reportergene, exp_paper WHERE exp_name.joinkey NOT IN (SELECT joinkey FROM exp_transgene) AND exp_name.joinkey = exp_reportergene.joinkey AND exp_name.joinkey = exp_paper.joinkey;" );	# this probably gets everything, but if something lacks a name or paper or reportergene it won't work.
$result = $dbh->prepare( "SELECT * FROM exp_reportergene WHERE joinkey NOT IN (SELECT joinkey FROM exp_transgene);" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $data{rep}{$row[0]} = $row[1]; } }

my $pgids = join"','", sort {$a<=>$b} keys %{ $data{rep} };
$result = $dbh->prepare( "SELECT * FROM exp_name WHERE joinkey IN ('$pgids');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $data{name}{$row[0]} = $row[1]; } }
$result = $dbh->prepare( "SELECT * FROM exp_paper WHERE joinkey IN ('$pgids');" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) { if ($row[0]) { $data{paper}{$row[0]} = $row[1]; } }

my @pgcommands;


foreach my $pgid  (sort {$a<=>$b} keys %{ $data{rep} }) {
  my $name = ''; my $paper = ''; my $rep = $data{rep}{$pgid};
  if ($data{paper}{$pgid}) { $paper = $data{paper}{$pgid}; } 	# else { print "ERR NO PAPER $pgid\n"; }
  if ($data{name}{$pgid}) { $name = $data{name}{$pgid}; } 	# else { print "ERR NO NAME $pgid\n"; }
  my $transgene_synonym = $name . '_Ex';				# daniela confirm that the underscore should still be there
  my $transgene = '';
  if ($trpNameToId{$transgene_synonym}) { $transgene = $trpNameToId{$transgene_synonym}; }		# if synonym to transgene ID mapping exists, get the transgene ID
    else { ($transgene) = &addToTrp($name, $transgene_synonym, $paper, $rep); }				# if it doesn't, generate the transgene object and get the new transgene ID
  my $transgene_with_doublequotes = '"' . $transgene . '"';
  push @pgcommands, "INSERT INTO exp_transgene VALUES ('$pgid', '$transgene_with_doublequotes')";
  push @pgcommands, "INSERT INTO exp_transgene_hst VALUES ('$pgid', '$transgene_with_doublequotes')";
  push @pgcommands, "INSERT INTO exp_reportergene_hst VALUES ('$pgid', NULL)";
  push @pgcommands, "DELETE FROM exp_reportergene WHERE joinkey = '$pgid'";
#   print "$pgid\t$name\t$paper\t$rep\n";
} # foreach my $pgid  (sort keys %{ $data{rep} })

foreach my $command (@pgcommands) {
  print "$command\n";
# UNCOMMENT TO TRANSFER DATA
  my $result2 = $dbh->do( $command );
} # foreach my $command (@pgcommands)

foreach my $author (sort keys %bad_authors) {
  my (@objs) = sort keys %{ $bad_authors{$author} };
  my $objs = join", ", @objs;
#   print "AUT $author\t$objs\n";
}

sub addToTrp {
  my ($name, $transgene_synonym, $paper, $remark) = @_;
  if ($remark =~ m/\'/) { $remark =~ s/\'/''/g; }
  my $curator = 'WBPerson12028';
#   my $fail = 'Fail';
  $pgid++;
  my $trpId = &pad8Zeros($pgid);
  my $trpName = 'WBTransgene' . $trpId;
#   $trpNameToId{$name} = $trpName;			# need to have the value with the _Ex here, not the exp_name
  $trpNameToId{$transgene_synonym} = $trpName;	
  push @pgcommands, "INSERT INTO trp_name VALUES ('$pgid', '$trpName')";
  push @pgcommands, "INSERT INTO trp_name_hst VALUES ('$pgid', '$trpName')";
  push @pgcommands, "INSERT INTO trp_synonym VALUES ('$pgid', '$transgene_synonym')";
  push @pgcommands, "INSERT INTO trp_synonym_hst VALUES ('$pgid', '$transgene_synonym')";
  push @pgcommands, "INSERT INTO trp_curator VALUES ('$pgid', '$curator')";
  push @pgcommands, "INSERT INTO trp_curator_hst VALUES ('$pgid', '$curator')";
#   push @pgcommands, "INSERT INTO trp_objpap_falsepos VALUES ('$pgid', '$fail')";
#   push @pgcommands, "INSERT INTO trp_objpap_falsepos_hst VALUES ('$pgid', '$fail')";
  push @pgcommands, "INSERT INTO trp_remark VALUES ('$pgid', '$remark')";
  push @pgcommands, "INSERT INTO trp_remark_hst VALUES ('$pgid', '$remark')";
  if ($paper) {
      push @pgcommands, "INSERT INTO trp_paper VALUES ('$pgid', '$paper')";
      push @pgcommands, "INSERT INTO trp_paper_hst VALUES ('$pgid', '$paper')"; }
    else {
      my $authors = $expr_authors{$name}; my @authors = split/\t/, $authors; my %good_auths;
      foreach my $author (@authors) {
        if ($author =~ m/WBPerson\d+/) {  $good_auths{$author}++; }			# already direct wbperson
          elsif ($auth_to_per{$author}) { $good_auths{$auth_to_per{$author}}++; }	# map author to person good
          else { $bad_authors{$author}{$name}++; } }					# not a good author
      my @person = sort keys %good_auths; unless ($person[0]) { print "ERR no paper nor person for $name\n"; }
      my $person = join'","', @person; $person = '"' . $person . '"';
      push @pgcommands, "INSERT INTO trp_person VALUES ('$pgid', '$person')";
      push @pgcommands, "INSERT INTO trp_person_hst VALUES ('$pgid', '$person')";
  }
  return $trpName;
} # sub addToTrp

sub getHighestPgid {                                    # get the highest joinkey from the primary tables
  my @highestPgidTables            = qw( name curator );
  my $datatype = 'trp';
  my $pgUnionQuery = "SELECT MAX(joinkey::integer) FROM ${datatype}_" . join" UNION SELECT MAX(joinkey::integer) FROM ${datatype}_", @highestPgidTables;
  my $result = $dbh->prepare( "SELECT max(max) FROM ( $pgUnionQuery ) AS max; " );
  $result->execute(); my @row = $result->fetchrow(); my $highest = $row[0];
  return $highest;
} # sub getHighestPgid

sub pad8Zeros {         # take a number and pad to 8 digits
  my $number = shift;
  if ($number =~ m/^0+/) { $number =~ s/^0+//g; }               # strip leading zeros
  if ($number < 10) { $number = '0000000' . $number; }
  elsif ($number < 100) { $number = '000000' . $number; }
  elsif ($number < 1000) { $number = '00000' . $number; }
  elsif ($number < 10000) { $number = '0000' . $number; }
  elsif ($number < 100000) { $number = '000' . $number; }
  elsif ($number < 1000000) { $number = '00' . $number; }
  elsif ($number < 10000000) { $number = '0' . $number; }
  return $number;
} # sub pad8Zeros

sub populateTrpNameToId {
  $result = $dbh->prepare( "SELECT trp_name.trp_name, trp_publicname.trp_publicname FROM trp_name, trp_publicname WHERE trp_name.joinkey = trp_publicname.joinkey;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $trpNameToId{$row[1]} = $row[0]; } }
  $result = $dbh->prepare( "SELECT trp_name.trp_name, trp_synonym.trp_synonym FROM trp_name, trp_synonym WHERE trp_name.joinkey = trp_synonym.joinkey;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) {
    my (@syns) = split/\|/, $row[1];				# synonyms are supposed to be pipe-separated
    unless ($syns[0]) { push @syns, $row[1]; }
    foreach my $syn (@syns) { 
      $syn =~ s/^\s+//; $syn =~ s/\s+$//;
      $trpNameToId{$syn} = $row[0]; } } }
} # sub populateTrpNameToId

sub readExprAce {
  $auth_to_per{"Hope IA"} = "WBPerson266";
  $auth_to_per{"Arnold JM"} = "WBPerson16468";
  $auth_to_per{"Bauer PK"} = "WBPerson5125";
  $auth_to_per{"Britton C"} = "WBPerson78";
  $auth_to_per{"Hashmi S"} = "WBPerson4368";
  $auth_to_per{"Herbert R"} = "WBPerson16472";
  $auth_to_per{"Krause MW"} = "WBPerson346";
  $auth_to_per{"Lustigman S"} = "WBPerson390";
  $auth_to_per{"Lynch AS"} = "WBPerson1232";
  $auth_to_per{"McCarroll D"} = "WBPerson16469";
  $auth_to_per{"Mohler WA"} = "WBPerson428";
  $auth_to_per{"Mounsey A"} = "WBPerson1716";
  $auth_to_per{"Royall CM"} = "WBPerson16473";
  $auth_to_per{"Seydoux GC"} = "WBPerson575";

  my $exprfile = '/home/acedb/draciti/Expr_pattern/ExprWS221.ace';
  $/ = "";
  open (IN, "<$exprfile") or die "Cannot open $exprfile : $!";
  my $junk = <IN>;
  while (my $object = <IN>) {
    unless ($object =~ m/Reference\s+\"WBPaper\d{8}\"/) {
      my ($name) = $object =~ m/Expr_pattern : \"(Expr\d+)\"/;
      my (@authors) = $object =~ m/Author\s+\"(.*)\"/g;
      my $authors = join"\t", @authors;
      $expr_authors{$name} = $authors; } }
  close (IN) or die "Cannot close $exprfile : $!";
  $/ = "\n";

  $expr_authors{"Expr1684"} = "WBPerson696";
  $expr_authors{"Expr1685"} = "WBPerson258";
  $expr_authors{"Expr2781"} = "WBPerson3909";
} # sub readExprAce


__END__

DELETE FROM exp_transgene WHERE exp_timestamp > '2012-02-06 12:00';
DELETE FROM exp_transgene_hst WHERE exp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_name WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_name_hst WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_curator WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_curator_hst WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_objpap_falsepos WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_objpap_falsepos_hst WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_remark WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_remark_hst WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_paper WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_paper_hst WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_person WHERE trp_timestamp > '2012-02-06 12:00';
DELETE FROM trp_person_hst WHERE trp_timestamp > '2012-02-06 12:00';




my $result = $dbh->prepare( 'SELECT * FROM two_comment WHERE two_comment ~ ?' );
$result->execute('elegans') or die "Cannot prepare statement: $DBI::errstr\n"; 

