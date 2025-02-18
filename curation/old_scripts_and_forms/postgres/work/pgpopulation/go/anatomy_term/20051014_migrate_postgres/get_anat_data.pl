#!/usr/bin/perl -w

# mishmash script.  Don't use.  Basis of all the moving scripts in the 20051014
# subdirectories.  2005 10 14


use strict;
use diagnostics;
use Pg;

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

my %anat;
my $result = $conn->exec( "SELECT * FROM ant_anatomy_term ;" );
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    if ($row[0] =~ m/^0/) { $anat{$row[0]}++; } } }

my @PGparameters = qw(curator anatomy_term);
my @PGsubparameters = qw( goterm goid paper_evidence person_evidence goinference
                          goinference_two aoinference comment qualifier
			  qualifier_two similarity with with_two );

$anat{'abcd'}++;
$anat{'1'}++;
$anat{'asdf'}++;

# foreach my $joinkey (sort keys %anat) {
#   foreach my $type (@PGparameters) {
#     my $table = "ant_" . $type;
#     my $pgcommand = "DELETE FROM $table WHERE joinkey = '$joinkey'; ";
#     my $result = $conn->exec( " $pgcommand ");
#     print "$pgcommand\n";
#   } # foreach my $type (@PGparameters)
# 
#   my @subtypes = qw( bio_ cell_ mol_ );
#   foreach my $subt ( @subtypes ) {
#     foreach my $type (@PGsubparameters) {
#       my $type = $subt . $type;
#       my $table = "ant_" . $type;
#       my $pgcommand = "DELETE FROM $table WHERE joinkey = '$joinkey'; ";
#       my $result = $conn->exec( " $pgcommand ");
#       print "$pgcommand\n";
#     } # foreach my $subt ( @subtypes )
#   } # foreach my $type (@PGsubparameters)
# } # foreach my $joinkey (sort keys %anat)


# deleted got_bio_aoinference got_anatomy_term got_cell_aoinference got_mol_aoinference 
my @PGgottables = qw( got_bio_qualifier         got_cell_goinference_two  got_locus                     got_mol_qualifier
                      got_bio_qualifier_two     got_cell_goterm		  got_mol_qualifier_two
                      got_bio_comment           got_bio_similarity        got_cell_paper_evidence	got_mol_comment           got_mol_with
                      got_bio_dbtype            got_bio_with              got_cell_person_evidence	got_mol_dbtype            got_mol_with_two
                      got_bio_dbtype_two        got_bio_with_two          got_cell_qualifier		got_mol_dbtype_two        got_obsoleteterm
                      got_bio_goid              got_cell_qualifier_two	  got_mol_goid                  got_pro_paper_evidence
                      got_bio_goinference       got_cell_comment          got_cell_with			got_mol_goinference       got_protein
                      got_bio_goinference_two   got_cell_dbtype           got_cell_with_two		got_mol_goinference_two   got_provisional
                      got_bio_goterm            got_cell_dbtype_two       got_curator			got_mol_goterm            got_sequence
                      got_bio_paper_evidence    got_cell_goid             got_dbtype			got_mol_paper_evidence    got_synonym
                      got_bio_person_evidence   got_cell_goinference      got_goterm			got_mol_person_evidence   got_wbgene );

foreach my $pgtable (@PGgottables) {
  print "\n$pgtable\n";
  foreach my $joinkey (sort keys %anat) {
    print "JOINKEY $joinkey\n";
    my $result = $conn->exec( "SELECT * FROM $pgtable WHERE joinkey = '$joinkey' AND $pgtable != '' AND $pgtable IS NOT NULL;" );
    while (my @row = $result->fetchrow) { 
      if ($row[1]) { print "$pgtable\t$joinkey\t$row[0]\t$row[1]\t$row[2]\t$row[3]\n"; }
    }
    $result = $conn->exec( "DELETE FROM $pgtable WHERE joinkey = '$joinkey';" );
  } # foreach my $joinkey (sort keys %anat)
} # foreach my $pgtable (@PGgottables)



__END__


  foreach my $type (@PGsubparameters) {
    my @subtypes = qw( bio_ cell_ mol_ );
    foreach my $subt ( @subtypes ) {
      my $type = $subt . $type;
      for my $i (1 .. 8) {
#         my $result = $conn->exec( "COPY got_${type}$i TO '/home/postgres/work/pgpopulation/anatomy_term/20051114_migrate_postgres/20051014_backup_and_delete_splittables/go_tables_without_anatomy/got_${type}${i}.pg'; " );
#         my $result = $conn->exec( "DROP TABLE got_${type}$i ; " );
#         foreach my $joinkey (sort keys %anat) {
#           my $result = $conn->exec( "SELECT * FROM got_${type}$i WHERE joinkey = '$joinkey';" );
#           while (my @row = $result->fetchrow) {
#             $hash{$type}{$joinkey}{$i}{val}{split} = $row[1];
#             $hash{$type}{$joinkey}{$i}{time}{split} = $row[2];
# #             print "got_${type}$i\t$row[0]\t$row[1]\t$row[2]\t$row[3]\n";
#           } # while (my @row = $result->fetchrow)  
#         } # foreach my $joinkey (sort keys %anat)
# #         print "\n";
      } # for my $i (1 .. 8)
    } # foreach my $subt ( @subtypes )
  } # foreach my $type (@PGsubparameters)

  foreach my $type (@PGparameters) {
    foreach my $joinkey (sort keys %anat) {
      my $result = $conn->exec( "SELECT * FROM got_$type WHERE joinkey = '$joinkey';" );
      while (my @row = $result->fetchrow) {
#         print "got_$type\t$row[0]\t$row[1]\t$row[2]\n";
      } # while (my @row = $result->fetchrow)
    } # foreach my $joinkey (sort keys %anat)
#     print "\n";
  } # foreach my $type (@PGparameters)

  my %hash;
  foreach my $type (@PGsubparameters) {
    my @subtypes = qw( bio_ cell_ mol_ );
    foreach my $subt ( @subtypes ) {
      my $type = $subt . $type;
      for my $i (1 .. 8) {
        foreach my $joinkey (sort keys %anat) {
          my $result = $conn->exec( "SELECT * FROM got_$type WHERE joinkey = '$joinkey';" );
          while (my @row = $result->fetchrow) {
            $hash{$type}{$joinkey}{$row[1]}{val}{order} = $row[2];
            $hash{$type}{$joinkey}{$row[1]}{time}{order} = $row[3];
#             print "got_${type}$i\t$row[0]\t$row[1]\t$row[2]\t$row[3]\n";
          } # while (my @row = $result->fetchrow)  
        } # foreach my $joinkey (sort keys %anat)
#         print "\n";
      } # for my $i (1 .. 8)
    } # foreach my $subt ( @subtypes )
  } # foreach my $type (@PGsubparameters)

  foreach my $type (@PGsubparameters) {
    my @subtypes = qw( bio_ cell_ mol_ );
    foreach my $subt ( @subtypes ) {
      my $type = $subt . $type;
      for my $i (1 .. 8) {
        foreach my $joinkey (sort keys %anat) {
          my $result = $conn->exec( "SELECT * FROM got_${type}$i WHERE joinkey = '$joinkey';" );
          while (my @row = $result->fetchrow) {
            $hash{$type}{$joinkey}{$i}{val}{split} = $row[1];
            $hash{$type}{$joinkey}{$i}{time}{split} = $row[2];
#             print "got_${type}$i\t$row[0]\t$row[1]\t$row[2]\t$row[3]\n";
          } # while (my @row = $result->fetchrow)  
        } # foreach my $joinkey (sort keys %anat)
#         print "\n";
      } # for my $i (1 .. 8)
    } # foreach my $subt ( @subtypes )
  } # foreach my $type (@PGsubparameters)

  # compare ordered tables (tables with got_order) and split tables (got_bio_goid1, got_bio_goid2, etc.)
  # results seem to indicate that order tables have latest and more data.  2005 10 14
foreach my $type (sort keys %hash) {
  foreach my $joinkey (sort keys %{ $hash{$type} }) {
    foreach my $i (sort keys %{ $hash{$type}{$joinkey} }) {
      unless ($hash{$type}{$joinkey}{$i}{val}{split} eq $hash{$type}{$joinkey}{$i}{val}{order}) {
        print "type $type joinkey $joinkey I $i\t";
        print "split $hash{$type}{$joinkey}{$i}{val}{split} order $hash{$type}{$joinkey}{$i}{val}{order}\n"; }
      unless ($hash{$type}{$joinkey}{$i}{time}{split} eq $hash{$type}{$joinkey}{$i}{time}{order}) {
        print "type $type joinkey $joinkey I $i\t";
        print "split $hash{$type}{$joinkey}{$i}{time}{split} order $hash{$type}{$joinkey}{$i}{time}{order}\n"; }
} } }
