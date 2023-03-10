#!/usr/bin/perl

# set crontab to execute this every other week.  Downloads the ontologies from the geneontology
# webpage.  reads the current files (just downloaded) into %terms and %obsolete hashes.  reads the
# previous set (from old_ontology/ directory) into %old_terms and %old_obsolete hashes.  populates
# postgres by deleting all entries and re-entering them via an insertfile script.  finds changes
# between old and new set and writes to .txt file, reads data in postgres and if anything in there
# is affected emails Ranjana.  moves ontology files to old_ontology/ directory.  2002 08 26
#
# updated &getCuratedTerms to push all loci into a HoA instead of just a hash.  when it checks to
# email ranjana, it now mentions the loci.  2002 12 16
#
# Added Carol and Kimberly to email recepients.  2004 01 12
#
# Doesn't seem to be working, Ranjana no longer cares about previous week's
# obsolete, just that the current obsoletes match somethin.  2005 03 31
#
# Changed to only match current obsoletes.  Changed because got_whatever_tables
# are now in one table with got_order instead of multiple separatet tables.
# 2005 03 31
#
# Updated to include Erich's script erichGo2ace.pl to generate a .ace file for go 
# terms and symlink to 
# http://tazendra.caltech.edu/~postgres/cgi-bin/data/go_terms_latest.ace  
# to be picked up by cronjob from altair.  Changed the cronjob from 1,8,15,22 to 
# every wednesday at 2am.  2005 09 15
#
# Exclude WBGene00000000 from list of things to check, since it's a test entry.  2005 11 09
#
# Was looking at go form data such that it would always write all entires, so it
# would look down the latest order for a given joinkey.  Changed to only write
# to form when data changes, so filtering through all go table data to only look
# at the latest entry.  2006 12 06
#
# We're getting rid of it because it's looking at old got_ tables.  
# Ranjana confirmed.  2011 06 03



use strict;
use diagnostics;
use Jex; # &getDate(); &mailer();
use DBI;

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";

chdir('/home/postgres/work/pgpopulation/go/go_curation') or die "Cannot go to /home/postgres/work/pgpopulation/go/go_curation ($!)";

my $line;				# line read from file

my %terms;
# my %old_terms;
my %obsolete;
# my %old_obsolete;
my %curated_terms;

my $date = &getDate();

&getNewOntologies();
&erichStuff();
&readOntologies();
# &readOldOntologies();			# no longer care about previous week's data.  2005 03 31
&populatePostgres();
# &dealWithDeprecatedTerms();		# no longer do obsolete checking here, use /home/acedb/ranjana/GO/ontology/gene_ontology_edit.obo 
					# instead with check_obsoletes.pl  2007 08 21
&moveOntologyFiles();

sub dealWithDeprecatedTerms {
  &getCuratedTerms();
#   my $flatfile = '/home/postgres/public_html/go_deprecated.txt';
  my $flatfile = 'go_deprecated.txt';
  open (OUT, ">>$flatfile") or die "Cannot open $flatfile : $!";

  my $mail_body = '';				# stuff to email Ranjana
  my $carol_body = ''; my $ranjana_body = ''; my $kimberly_body = '';	# separate parts by curator

  my %curators;					# hash of curators by loci (joinkey) in postgres
  my $result = $dbh->prepare( "SELECT * FROM got_curator;" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
  while (my @row = $result->fetchrow) { $curators{$row[0]} = $row[1]; } 

  foreach my $ids (sort keys %obsolete) {
    if ($curated_terms{$ids}) { 
      foreach my $loci (@{ $curated_terms{$ids}}) { 
        if ($curators{$loci} =~ m/Carol/) { $carol_body .= "OBSOLETE\tCarol    \t$loci\t$ids $obsolete{$ids}\n"; }
        elsif ($curators{$loci} =~ m/Ranjana/) { $ranjana_body .= "OBSOLETE\tRanjana \t$loci\t$ids $obsolete{$ids}\n"; }
        elsif ($curators{$loci} =~ m/Kimberly/) { $kimberly_body .= "OBSOLETE\tKimberly\t$loci\t$ids $obsolete{$ids}\n"; }
        else { $ mail_body .= "OBSOLETE\tUnknown\t$loci\t$ids $obsolete{$ids}\n" }	# not the suppossed three
    } }
  } # foreach my $ids (sort keys %obsolete)

  $mail_body .= $kimberly_body; $mail_body .= $carol_body; $mail_body .= $ranjana_body;

  unless ($mail_body) { $mail_body = "Checked Obsolete Terms, there are no obsolete terms curated\n"; }
  if ($mail_body) { 
    my $user = 'automatic_script@minerva.caltech.edu';
    my $email = 'ranjana@its.caltech.edu, vanauken@its.caltech.edu';
#     my $email = 'azurebrd';
    my $subject = 'Deprecated Go Term';
    &mailer($user, $email, $subject, $mail_body);
    print OUT "$mail_body\n\n";
  } # if ($mail_body)
  
  close (OUT) or die "Cannot close $flatfile : $!";
} # sub dealWithDeprecatedTerms

sub getNewOntologies {
  system(`wget http://www.geneontology.org/ontology/function.ontology`);
  system(`wget http://www.geneontology.org/ontology/component.ontology`);
  system(`wget http://www.geneontology.org/ontology/process.ontology`);
  system(`wget ftp://ftp.geneontology.org/pub/go/ontology/GO.defs`);	# for Erich's stuff 2005 09 15
} # sub getNewOntologies

sub erichStuff {
  my $date = &getSimpleSecDate();
  my $directory = '/home/postgres/work/pgpopulation/go/go_curation';
  my $go_file = $directory . '/old_ace/go_terms_' . $date . '.ace';
  my $location_of_latest = '/home/postgres/public_html/cgi-bin/data/go_terms_latest.ace';
  unlink ("$location_of_latest") or die "Cannot unlink $location_of_latest : $!";	# unlink symlink to latest
  `${directory}/erichGo2ace.pl $directory > $go_file`;
  symlink("$go_file", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";  
  my @old_files = </home2/postgres/work/pgpopulation/go/go_curation/old_ace/go_terms_*>;	# get a list of old files to delete 2007 08 16
  `rm $old_files[0]`;		# delete the oldest file so there's always the same number of copies 2007 08 16
} # sub erichStuff

sub moveOntologyFiles {
  rename ("/home/postgres/work/pgpopulation/go/go_curation/function.ontology", "/home/postgres/work/pgpopulation/go/go_curation/old_ontology/function.ontology");
  rename ("/home/postgres/work/pgpopulation/go/go_curation/component.ontology", "/home/postgres/work/pgpopulation/go/go_curation/old_ontology/component.ontology");
  rename ("/home/postgres/work/pgpopulation/go/go_curation/process.ontology", "/home/postgres/work/pgpopulation/go/go_curation/old_ontology/process.ontology");
  rename ("/home/postgres/work/pgpopulation/go/go_curation/GO.defs", "/home/postgres/work/pgpopulation/go/go_curation/old_ontology/GO.defs");
} # sub moveOntologyFiles

sub populatePostgres {
  my $insertfile = '/home/postgres/work/pgpopulation/go/go_curation/insertfile.pl';
  open (INS, ">$insertfile") or die "Cannot create $insertfile : $!";
  print INS "#!\/usr\/bin\/perl -w\n";
  print INS "\n";
  print INS "use lib qw( \/usr\/lib/perl5\/site_perl\/5.6.1\/i686-linux\/ );\n";
  print INS "use DBI;\n";
  print INS "\n";
  print INS "my \$dbh = DBI->connect(\"dbi:Pg:dbname=testdb\", \"\", \"\") or die \"Cannot connect to database\n;\n";
  print INS "my \$result = \$dbh\->do( \"DELETE FROM got_goterm;\");\n";
  print INS "\$result = \$dbh\->do( \"DELETE FROM got_obsoleteterm;\");\n";

  foreach my $ids (sort keys %obsolete) {
    my $filtered_id = &filterForPostgres($ids);
    my $filtered_obsolete = &filterForPostgres($obsolete{$ids});
    print INS "\$result = \$dbh\->do( \"INSERT INTO got_obsoleteterm VALUES (\'$filtered_id\', \'$filtered_obsolete\')\");\n";
  } # foreach my $ids (sort keys %obsolete)
  
  foreach my $ids (sort keys %terms) {
    my $filtered_id = &filterForPostgres($ids);
    my $filtered_term = &filterForPostgres($terms{$ids});
    print INS "\$result = \$dbh\->do( \"INSERT INTO got_goterm VALUES (\'$filtered_id\', \'$filtered_term\')\");\n";
  } # foreach my $ids (sort keys %terms)
  
  close (INS) or die "Cannot close $insertfile : $!";
  chmod 0755, $insertfile;
  system("$insertfile");
} # sub populatePostgres

sub readOntologies {
  my @ontologies = </home/postgres/work/pgpopulation/go/go_curation/*.ontology>; 
  foreach my $ontology (@ontologies) {
    open (IN, "<$ontology") or die "Cannot open $ontology : $!";
    while ($line = <IN>) {
      if ($line =~ m/GO:/) { &getGoTerm($line); } 	# if it has a go term, put in hash
  
      if ($line =~ m/^  %obsolete/) {	# start reading obsolete terms
        $line = <IN>;			# read first obsolete term
        while ($line !~ m/^  %/) {	# until it matches the next set
            # if it has an obsolete term, put in obsolete hash
          if ($line =~ m/GO:/) { &getObsoleteTerm($line); } 
          $line = <IN>;			# read more terms until no longer obsolete
        } # while ($line !~ m/^  %/)
  
          # no longer obsolete, process good term then exit loop and process other terms
        if ($line =~ m/GO:/) { &getGoTerm($line); } 	# if it has a go term, put in hash
      } # if ($line =~ m/^  %obsolete/)
    } # while (my $line = <IN>)
    close (IN) or die "Cannot close $ontology : $!";
  } # foreach my $ontology (@ontologies)
} # sub readOntologies

sub readOldOntologies {
  my @old_ontologies = </home/postgres/work/pgpopulation/go/go_curation/old_ontology/*.ontology>; 
  foreach my $ontology (@old_ontologies) {
    open (IN, "<$ontology") or die "Cannot open $ontology : $!";
    while ($line = <IN>) {
      if ($line =~ m/GO:/) { &getOldGoTerm($line); } 	# if it has a go term, put in hash
  
      if ($line =~ m/^  %obsolete/) {	# start reading obsolete terms
        $line = <IN>;			# read first obsolete term
        while ($line !~ m/^  %/) {	# until it matches the next set
            # if it has an obsolete term, put in obsolete hash
          if ($line =~ m/GO:/) { &getOldObsoleteTerm($line); } 
          $line = <IN>;			# read more terms until no longer obsolete
        } # while ($line !~ m/^  %/)
  
          # no longer obsolete, process good term then exit loop and process other terms
        if ($line =~ m/GO:/) { &getOldGoTerm($line); } 	# if it has a go term, put in hash
      } # if ($line =~ m/^  %obsolete/)
    } # while (my $line = <IN>)
    close (IN) or die "Cannot close $ontology : $!";
  } # foreach my $ontology (@ontologies)
} # sub readOldOntologies


sub getGoTerm {
  my $line = shift;
  my @terms = split /[<%]/, $line;
  foreach my $term (@terms) {
    if ($term =~ m/^ ?(.*) ; (GO:\d+) ?/) { $terms{$2} = $1; }
  } # foreach my $term (@terms)
} # sub getGoTerm

sub getObsoleteTerm {
  my $line = shift;
  my @terms = split /[<%]/, $line;
  foreach my $term (@terms) {
    if ($term =~ m/^ ?(.*) ; (GO:\d+) ?/) { $obsolete{$2} = $1; }
  } # foreach my $term (@terms)
} # sub getObsoleteTerm

sub filterForPostgres { # filter values for postgres
  my $value = shift;
  $value =~ s/\'/''/g;
  $value =~ s/\$/\\\$/g;
  return $value;
} # sub filterForPostgres

sub getCuratedTerms {			# get from got_order type tables  2005 03 31
  my @tables = qw( got_bio_goid got_cell_goid got_mol_goid ); 
  foreach my $table (@tables) {
#     my %ignore;						# hash of stuff that has gotten it's values read down to got_order 1
    my $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ '[A-Za-z]' AND joinkey != 'cgc3' AND joinkey != 'abcd' AND joinkey != 'test-1' AND joinkey != 'asdf' AND joinkey != 'zk512.1' AND joinkey != 'WBGene00000000' ORDER BY got_timestamp ;");	# changed this so terms are there only if they have changed, so can't look down the order at the latest timestamp data.  2006 12 06
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#     my $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ '[A-Za-z]' AND joinkey != 'cgc3' AND joinkey != 'abcd' AND joinkey != 'test-1' AND joinkey != 'asdf' AND joinkey != 'zk512.1' AND joinkey != 'WBGene00000000' ORDER BY got_timestamp DESC;");
#     my $result = $dbh->prepare( "SELECT * FROM $table WHERE joinkey ~ '[A-Za-z]' AND joinkey != 'cgc3' AND joinkey != 'abcd' AND joinkey != 'test-1' AND joinkey != 'asdf' AND joinkey != 'zk512.1';");
#     my $result = $dbh->prepare( "SELECT * FROM $table;" );
#     $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
#     print "SELECT * FROM $table WHERE joinkey ~ '[A-Za-z]' AND joinkey != 'cgc3' AND joinkey != 'abcd' AND joinkey != 'asdf' AND joinkey != 'zk512.1' ORDER BY got_timestamp DESC;\n";
    my %filter = ();
    while (my @row = $result->fetchrow) { 
#       if ($ignore{$row[0]}) { next; }			# stuff that got to got_order 1 can be ignored
      $filter{$row[0]}{$row[1]} = $row[2];
#       if ($row[1] == 1) { $ignore{$row[0]}++; }		# stuff that got to got_order 1 can be ignored
    } # while (my @row = $result->fetchrow) 
    foreach my $joinkey (sort keys %filter) {
      foreach my $order (sort keys %{ $filter{$joinkey}}) {
        next unless $filter{$joinkey}{$order};
        my $goid = $filter{$joinkey}{$order};
        if ($goid) {
          my @ids = $goid =~ m/(\d+)/g;
          foreach my $id (@ids) { $id = 'GO:' . $id; push @{ $curated_terms{$id} }, $joinkey; } } } }
  } # foreach my $table (@tables)
} # sub getCuratedTerms

__END__

sub getCuratedTermsOldStaticTables {
  my @tables = qw(got_bio_goid1 got_bio_goid2 got_bio_goid3 got_bio_goid4 
                  got_cell_goid1 got_cell_goid2 got_cell_goid3 got_cell_goid4 
                  got_mol_goid1 got_mol_goid2 got_mol_goid3 got_mol_goid4 ); 
  foreach my $table (@tables) {
    my $result = $dbh->prepare( "SELECT * FROM $table;" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n";
    while (my @row = $result->fetchrow) { 
      if ($row[1]) {
        my @ids = $row[1] =~ m/(\d+)/g;
#         foreach my $id (@ids) { $id = 'GO:' . $id; $curated_terms{$id}++; }
        foreach my $id (@ids) { $id = 'GO:' . $id; push @{ $curated_terms{$id} }, $row[0]; }
      } # if ($row[1])
    } # while (my @row = $result->fetchrow) 
  } # foreach my $table (@tables)
} # sub getCuratedTerms

sub dealWithDeprecatedTerms2002way {
  &getCuratedTerms();
#   foreach my $curated_term (sort keys %curated_terms) { print "-=${curated_term}=-\n"; }
  my $flatfile = '/home/postgres/public_html/go_deprecated.txt';
  open (OUT, ">>$flatfile") or die "Cannot open $flatfile : $!";

  my $mail_body = '';				# stuff to email Ranjana
  
  foreach my $ids (sort keys %obsolete) {
    unless ($old_obsolete{$ids}) { 
      print OUT "$date\tNEW OBSOLETE\t$ids $obsolete{$ids}\n"; 
      if ($curated_terms{$ids}) { foreach my $loci (@{ $curated_terms{$ids}}) { $mail_body .= "NEW OBSOLETE\t$loci\t$ids $obsolete{$ids}\n"; } }
    } # unless ($old_obsolete{$ids}) 
  } # foreach my $ids (sort keys %obsolete)
  
  foreach my $ids (sort keys %terms) {
  #   unless ($old_terms{$ids}) { print "NEW TERM $ids $terms{$ids}\n"; }
  } # foreach my $ids (sort keys %terms)
  
  foreach my $ids (sort keys %old_obsolete) {
    unless ($obsolete{$ids}) { 
      print OUT "$date\tDELETED OBSOLETE\t$ids $old_obsolete{$ids}\n"; 
      if ($curated_terms{$ids}) { foreach my $loci (@{ $curated_terms{$ids}}) { $mail_body .= "DELETED OBSOLETE\t$loci\t$ids $old_obsolete{$ids}\n"; } }
    } # unless ($obsolete{$ids}) 
  } # foreach my $ids (sort keys %old_obsolete)
  
  foreach my $ids (sort keys %old_terms) {
    unless ($terms{$ids}) { 
      print OUT "$date\tDELETED TERM\t$ids $old_terms{$ids}\n"; 
      if ($curated_terms{$ids}) { foreach my $loci (@{ $curated_terms{$ids}}) { $mail_body .= "DELETED TERM\t$loci\t$ids $old_terms{$ids}\n"; } }
    } # unless ($terms{$ids}) 
  } # foreach my $ids (sort keys %old_terms)
  
  print OUT "\n\n";
  if ($mail_body) { 
    my $user = 'automatic_script@minerva.caltech.edu';
    my $email = 'ranjana@its.caltech.edu, vanauken@its.caltech.edu';
    my $subject = 'Deprecated Go Term';
    &mailer($user, $email, $subject, $mail_body);
  } # if ($mail_body)
  
  close (OUT) or die "Cannot close $flatfile : $!";
} # sub sub dealWithDeprecatedTerms2002way

sub getOldGoTerm {
  my $line = shift;
  my @terms = split /[<%]/, $line;
  foreach my $term (@terms) {
    if ($term =~ m/^ ?(.*) ; (GO:\d+) ?/) { $old_terms{$2} = $1; }
  } # foreach my $term (@terms)
} # sub getOldGoTerm

sub getOldObsoleteTerm {
  my $line = shift;
  my @terms = split /[<%]/, $line;
  foreach my $term (@terms) {
    if ($term =~ m/^ ?(.*) ; (GO:\d+) ?/) { $old_obsolete{$2} = $1; }
  } # foreach my $term (@terms)
} # sub getOldObsoleteTerm

