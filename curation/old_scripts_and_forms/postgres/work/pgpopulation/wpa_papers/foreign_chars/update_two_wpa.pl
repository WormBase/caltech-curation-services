#!/usr/bin/perl -w

# take out foreign characters from names in Persons and Authors and Abstracts.
# For Cecilia (and Andrei, but he didn't say anything) 2006 05 04

use strict;
use diagnostics;
use Pg;

print "pie\n";

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# my @tables = qw( two_aka_firstname two_aka_lastname two_aka_middlename two_apu_firstname two_apu_lastname two_apu_middlename two_city two_comment two_contactdata two_country two_email two_fax two_firstname two_fullname two_groups two_hide two_institution two_lab two_labphone two_lastname two_left_field two_lineage two_mainphone two_middlename two_officephone two_old_email two_oldlab two_otherphone two_paper two_pis two_post two_privacy two_sequence two_standardname two_state two_street two_unable_to_contact two_webpage two_wormbase_comment wpa_abstract wpa_affiliation wpa_author wpa_author_index wpa_author_possible wpa_author_sent wpa_author_verified wpa_checked_out wpa_comments wpa_contained_in wpa_contains wpa_date_published wpa_editor wpa_electronic_path_md5 wpa_electronic_path_type wpa_electronic_type_index wpa_erratum wpa_fulltext_url wpa_gene wpa_hardcopy wpa_identifier wpa_in_book wpa_journal wpa_keyword wpa_nematode_paper wpa_pages wpa_publisher wpa_remark wpa_rnai_curation wpa_title wpa_type wpa_type_index wpa_volume wpa_year );

my @tables = qw( two_aka_firstname two_aka_lastname two_aka_middlename two_apu_firstname two_apu_lastname two_apu_middlename two_firstname two_fullname two_lastname two_middlename two_standardname wpa_author_index wpa_abstract wpa_title );

my $outfile = "outfile";
open(OUT, ">$outfile") or die "Cannot create $outfile : $!";

foreach my $table (@tables) {
  my $result = $conn->exec( "SELECT $table FROM $table;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) {
      my $orig = $row[0]; my $change = $row[0];

      if ($change =~ m/[‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý]/) {
        if ($change =~ m/‚/) { $change =~ s/‚/,/g; }
        if ($change =~ m/„/) { $change =~ s/„/"/g; }
        if ($change =~ m/…/) { $change =~ s/…/.../g; }
        if ($change =~ m/ˆ/) { $change =~ s/ˆ/^/g; }
        if ($change =~ m/Š/) { $change =~ s/Š/S/g; }
        if ($change =~ m/‹/) { $change =~ s/‹/</g; }
        if ($change =~ m/Œ/) { $change =~ s/Œ/OE/g; }
        if ($change =~ m/Ž/) { $change =~ s/Ž/Z/g; }
        if ($change =~ m/‘/) { $change =~ s/‘/'/g; }
        if ($change =~ m/’/) { $change =~ s/’/'/g; }
        if ($change =~ m/“/) { $change =~ s/“/"/g; }
        if ($change =~ m/”/) { $change =~ s/”/"/g; }
        if ($change =~ m/—/) { $change =~ s/—/-/g; }
        if ($change =~ m/˜/) { $change =~ s/˜/~/g; }
        if ($change =~ m/š/) { $change =~ s/š/s/g; }
        if ($change =~ m/›/) { $change =~ s/›/>/g; }
        if ($change =~ m/œ/) { $change =~ s/œ/oe/g; }
        if ($change =~ m/ž/) { $change =~ s/ž/z/g; }
        if ($change =~ m/Ÿ/) { $change =~ s/Ÿ/y/g; }
        if ($change =~ m/ª/) { $change =~ s/ª/a/g; }
        if ($change =~ m/«/) { $change =~ s/«/"/g; }
        if ($change =~ m/­/) { $change =~ s/­/-/g; }
        if ($change =~ m/¯/) { $change =~ s/¯/-/g; }
        if ($change =~ m/±/) { $change =~ s/±/+\/-/g; }
        if ($change =~ m/·/) { $change =~ s/·/-/g; }
        if ($change =~ m/»/) { $change =~ s/»/"/g; }
        if ($change =~ m/¼/) { $change =~ s/¼/1\/4/g; }
        if ($change =~ m/½/) { $change =~ s/½/1\/2/g; }
        if ($change =~ m/¾/) { $change =~ s/¾/3\/4/g; }
        if ($change =~ m/À/) { $change =~ s/À/A/g; }
        if ($change =~ m/Á/) { $change =~ s/Á/A/g; }
        if ($change =~ m/Â/) { $change =~ s/Â/A/g; }
        if ($change =~ m/Ã/) { $change =~ s/Ã/A/g; }
        if ($change =~ m/Ä/) { $change =~ s/Ä/A/g; }
        if ($change =~ m/Å/) { $change =~ s/Å/A/g; }
        if ($change =~ m/Æ/) { $change =~ s/Æ/AE/g; }
        if ($change =~ m/Ç/) { $change =~ s/Ç/C/g; }
        if ($change =~ m/È/) { $change =~ s/È/E/g; }
        if ($change =~ m/É/) { $change =~ s/É/E/g; }
        if ($change =~ m/Ê/) { $change =~ s/Ê/E/g; }
        if ($change =~ m/Ë/) { $change =~ s/Ë/E/g; }
        if ($change =~ m/Ì/) { $change =~ s/Ì/I/g; }
        if ($change =~ m/Í/) { $change =~ s/Í/I/g; }
        if ($change =~ m/Î/) { $change =~ s/Î/I/g; }
        if ($change =~ m/Ï/) { $change =~ s/Ï/I/g; }
        if ($change =~ m/Ð/) { $change =~ s/Ð/D/g; }
        if ($change =~ m/Ñ/) { $change =~ s/Ñ/N/g; }
        if ($change =~ m/Ò/) { $change =~ s/Ò/O/g; }
        if ($change =~ m/Ó/) { $change =~ s/Ó/O/g; }
        if ($change =~ m/Ô/) { $change =~ s/Ô/O/g; }
        if ($change =~ m/Õ/) { $change =~ s/Õ/O/g; }
        if ($change =~ m/Ö/) { $change =~ s/Ö/O/g; }
        if ($change =~ m/×/) { $change =~ s/×/x/g; }
        if ($change =~ m/Ø/) { $change =~ s/Ø/O/g; }
        if ($change =~ m/Ù/) { $change =~ s/Ù/U/g; }
        if ($change =~ m/Ú/) { $change =~ s/Ú/U/g; }
        if ($change =~ m/Û/) { $change =~ s/Û/U/g; }
        if ($change =~ m/Ü/) { $change =~ s/Ü/U/g; }
        if ($change =~ m/Ý/) { $change =~ s/Ý/Y/g; }
        if ($change =~ m/ß/) { $change =~ s/ß/B/g; }
        if ($change =~ m/à/) { $change =~ s/à/a/g; }
        if ($change =~ m/á/) { $change =~ s/á/a/g; }
        if ($change =~ m/â/) { $change =~ s/â/a/g; }
        if ($change =~ m/ã/) { $change =~ s/ã/a/g; }
        if ($change =~ m/ä/) { $change =~ s/ä/a/g; }
        if ($change =~ m/å/) { $change =~ s/å/a/g; }
        if ($change =~ m/æ/) { $change =~ s/æ/ae/g; }
        if ($change =~ m/ç/) { $change =~ s/ç/c/g; }
        if ($change =~ m/è/) { $change =~ s/è/e/g; }
        if ($change =~ m/é/) { $change =~ s/é/e/g; }
        if ($change =~ m/ê/) { $change =~ s/ê/e/g; }
        if ($change =~ m/ë/) { $change =~ s/ë/e/g; }
        if ($change =~ m/ì/) { $change =~ s/ì/i/g; }
        if ($change =~ m/í/) { $change =~ s/í/i/g; }
        if ($change =~ m/î/) { $change =~ s/î/i/g; }
        if ($change =~ m/ï/) { $change =~ s/ï/i/g; }
        if ($change =~ m/ð/) { $change =~ s/ð/o/g; }
        if ($change =~ m/ñ/) { $change =~ s/ñ/n/g; }
        if ($change =~ m/ò/) { $change =~ s/ò/o/g; }
        if ($change =~ m/ó/) { $change =~ s/ó/o/g; }
        if ($change =~ m/ô/) { $change =~ s/ô/o/g; }
        if ($change =~ m/õ/) { $change =~ s/õ/o/g; }
        if ($change =~ m/ö/) { $change =~ s/ö/o/g; }
        if ($change =~ m/÷/) { $change =~ s/÷/\//g; }
        if ($change =~ m/ø/) { $change =~ s/ø/o/g; }
        if ($change =~ m/ù/) { $change =~ s/ù/u/g; }
        if ($change =~ m/ú/) { $change =~ s/ú/u/g; }
        if ($change =~ m/û/) { $change =~ s/û/u/g; }
        if ($change =~ m/ü/) { $change =~ s/ü/u/g; }
        if ($change =~ m/ý/) { $change =~ s/ý/y/g; }
        print OUT "CHANGE $change ORIG $orig END\n";
        my $command = "UPDATE $table SET $table = '$change' WHERE $table = '$orig'";
        print OUT "$command\n";
#         my $result2 = $conn->exec( $command );	# UNCOMMENT THIS FOR THIS TO WORK
      }
   
      if ($change =~ m/€/) { print OUT "ERROR  €\n"; }
      if ($change =~ m/ƒ/) { print OUT "ERROR  ƒ\n"; }
      if ($change =~ m/†/) { print OUT "ERROR  †\n"; }
      if ($change =~ m/‡/) { print OUT "ERROR  ‡\n"; }
      if ($change =~ m/‰/) { print OUT "ERROR  ‰\n"; }
      if ($change =~ m/•/) { print OUT "ERROR  •\n"; }
      if ($change =~ m/™/) { print OUT "ERROR  ™\n"; }
      if ($change =~ m/¡/) { print OUT "ERROR  ¡\n"; }
      if ($change =~ m/¢/) { print OUT "ERROR  ¢\n"; }
      if ($change =~ m/£/) { print OUT "ERROR  £\n"; }
      if ($change =~ m/¤/) { print OUT "ERROR  ¤\n"; }
      if ($change =~ m/¥/) { print OUT "ERROR  ¥\n"; }
      if ($change =~ m/¦/) { print OUT "ERROR  ¦\n"; }
      if ($change =~ m/§/) { print OUT "ERROR  §\n"; }
      if ($change =~ m/¨/) { print OUT "ERROR  ¨\n"; }
      if ($change =~ m/©/) { print OUT "ERROR  ©\n"; }
      if ($change =~ m/¬/) { print OUT "ERROR  ¬\n"; }
      if ($change =~ m/®/) { print OUT "ERROR  ®\n"; }
      if ($change =~ m/°/) { print OUT "ERROR  °\n"; }
      if ($change =~ m/²/) { print OUT "ERROR  ²\n"; }
      if ($change =~ m/³/) { print OUT "ERROR  ³\n"; }
      if ($change =~ m/´/) { print OUT "ERROR  ´\n"; }
      if ($change =~ m/µ/) { print OUT "ERROR  µ\n"; }
      if ($change =~ m/¶/) { print OUT "ERROR  ¶\n"; }		# this character is part of some of the above characters, so must convert the above first
      if ($change =~ m/¹/) { print OUT "ERROR  ¹\n"; }
      if ($change =~ m/º/) { print OUT "ERROR  º\n"; }
      if ($change =~ m/¿/) { print OUT "ERROR  ¿\n"; }
      if ($change =~ m/þ/) { print OUT "ERROR  þ\n"; }
      if ($change =~ m/Þ/) { print OUT "ERROR  Þ\n"; }

#       if ($change =~ m/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]/) { $change =~ s/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]//g; 
#         my $command = "UPDATE $table SET $table = '$change' WHERE $table = '$orig'";
# #         print OUT "$command\n";
# #         my $result2 = $conn->exec( $command );
#       }
#       $orig = $change;					# orig has been changed to change
#       if ($change =~ m/[‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý]/) {
# #         print OUT "TWO UPDATE $change\n";
#       }
  } } 
} # foreach my $table (@tables)


close (OUT) or die "Cannot close $outfile : $!";



__END__

my $result = $conn->exec( "SELECT * FROM wpa_author_index WHERE wpa_author_index ~ 'diger';" );
while (my @row = $result->fetchrow) {
  if ($row[1]) {
# print "OUT $row[1] OUT\n";
    my $orig = $row[1]; my $change = $row[1];
    if ($change =~ m/[‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý]/) {
      if ($change =~ m/‚/) { $change =~ s/‚/,/g; }
      if ($change =~ m/„/) { $change =~ s/„/"/g; }
      if ($change =~ m/…/) { $change =~ s/…/.../g; }
      if ($change =~ m/ˆ/) { $change =~ s/ˆ/^/g; }
      if ($change =~ m/Š/) { $change =~ s/Š/S/g; }
      if ($change =~ m/‹/) { $change =~ s/‹/</g; }
      if ($change =~ m/Œ/) { $change =~ s/Œ/OE/g; }
      if ($change =~ m/Ž/) { $change =~ s/Ž/Z/g; }
      if ($change =~ m/‘/) { $change =~ s/‘/'/g; }
      if ($change =~ m/’/) { $change =~ s/’/'/g; }
      if ($change =~ m/“/) { $change =~ s/“/"/g; }
      if ($change =~ m/”/) { $change =~ s/”/"/g; }
      if ($change =~ m/—/) { $change =~ s/—/-/g; }
      if ($change =~ m/˜/) { $change =~ s/˜/~/g; }
      if ($change =~ m/š/) { $change =~ s/š/s/g; }
      if ($change =~ m/›/) { $change =~ s/›/>/g; }
      if ($change =~ m/œ/) { $change =~ s/œ/oe/g; }
      if ($change =~ m/ž/) { $change =~ s/ž/z/g; }
      if ($change =~ m/Ÿ/) { $change =~ s/Ÿ/y/g; }
      if ($change =~ m/ª/) { $change =~ s/ª/a/g; }
      if ($change =~ m/«/) { $change =~ s/«/"/g; }
      if ($change =~ m/­/) { $change =~ s/­/-/g; }
      if ($change =~ m/¯/) { $change =~ s/¯/-/g; }
      if ($change =~ m/±/) { $change =~ s/±/+\/-/g; }
      if ($change =~ m/·/) { $change =~ s/·/-/g; }
      if ($change =~ m/»/) { $change =~ s/»/"/g; }
      if ($change =~ m/¼/) { $change =~ s/¼/1\/4/g; }
      if ($change =~ m/½/) { $change =~ s/½/1\/2/g; }
      if ($change =~ m/¾/) { $change =~ s/¾/3\/4/g; }
      if ($change =~ m/À/) { $change =~ s/À/A/g; }
      if ($change =~ m/Á/) { $change =~ s/Á/A/g; }
      if ($change =~ m/Â/) { $change =~ s/Â/A/g; }
      if ($change =~ m/Ã/) { $change =~ s/Ã/A/g; }
      if ($change =~ m/Ä/) { $change =~ s/Ä/A/g; }
      if ($change =~ m/Å/) { $change =~ s/Å/A/g; }
      if ($change =~ m/Æ/) { $change =~ s/Æ/AE/g; }
      if ($change =~ m/Ç/) { $change =~ s/Ç/C/g; }
      if ($change =~ m/È/) { $change =~ s/È/E/g; }
      if ($change =~ m/É/) { $change =~ s/É/E/g; }
      if ($change =~ m/Ê/) { $change =~ s/Ê/E/g; }
      if ($change =~ m/Ë/) { $change =~ s/Ë/E/g; }
      if ($change =~ m/Ì/) { $change =~ s/Ì/I/g; }
      if ($change =~ m/Í/) { $change =~ s/Í/I/g; }
      if ($change =~ m/Î/) { $change =~ s/Î/I/g; }
      if ($change =~ m/Ï/) { $change =~ s/Ï/I/g; }
      if ($change =~ m/Ð/) { $change =~ s/Ð/D/g; }
      if ($change =~ m/Ñ/) { $change =~ s/Ñ/N/g; }
      if ($change =~ m/Ò/) { $change =~ s/Ò/O/g; }
      if ($change =~ m/Ó/) { $change =~ s/Ó/O/g; }
      if ($change =~ m/Ô/) { $change =~ s/Ô/O/g; }
      if ($change =~ m/Õ/) { $change =~ s/Õ/O/g; }
      if ($change =~ m/Ö/) { $change =~ s/Ö/O/g; }
      if ($change =~ m/×/) { $change =~ s/×/x/g; }
      if ($change =~ m/Ø/) { $change =~ s/Ø/O/g; }
      if ($change =~ m/Ù/) { $change =~ s/Ù/U/g; }
      if ($change =~ m/Ú/) { $change =~ s/Ú/U/g; }
      if ($change =~ m/Û/) { $change =~ s/Û/U/g; }
      if ($change =~ m/Ü/) { $change =~ s/Ü/U/g; }
      if ($change =~ m/Ý/) { $change =~ s/Ý/Y/g; }
      if ($change =~ m/ß/) { $change =~ s/ß/B/g; }
      if ($change =~ m/à/) { $change =~ s/à/a/g; }
      if ($change =~ m/á/) { $change =~ s/á/a/g; }
      if ($change =~ m/â/) { $change =~ s/â/a/g; }
      if ($change =~ m/ã/) { $change =~ s/ã/a/g; }
      if ($change =~ m/ä/) { $change =~ s/ä/a/g; }
      if ($change =~ m/å/) { $change =~ s/å/a/g; }
      if ($change =~ m/æ/) { $change =~ s/æ/ae/g; }
      if ($change =~ m/ç/) { $change =~ s/ç/c/g; }
      if ($change =~ m/è/) { $change =~ s/è/e/g; }
      if ($change =~ m/é/) { $change =~ s/é/e/g; }
      if ($change =~ m/ê/) { $change =~ s/ê/e/g; }
      if ($change =~ m/ë/) { $change =~ s/ë/e/g; }
      if ($change =~ m/ì/) { $change =~ s/ì/i/g; }
      if ($change =~ m/í/) { $change =~ s/í/i/g; }
      if ($change =~ m/î/) { $change =~ s/î/i/g; }
      if ($change =~ m/ï/) { $change =~ s/ï/i/g; }
      if ($change =~ m/ð/) { $change =~ s/ð/o/g; }
      if ($change =~ m/ñ/) { $change =~ s/ñ/n/g; }
      if ($change =~ m/ò/) { $change =~ s/ò/o/g; }
      if ($change =~ m/ó/) { $change =~ s/ó/o/g; }
      if ($change =~ m/ô/) { $change =~ s/ô/o/g; }
      if ($change =~ m/õ/) { $change =~ s/õ/o/g; }
      if ($change =~ m/ö/) { $change =~ s/ö/o/g; }
      if ($change =~ m/÷/) { $change =~ s/÷/\//g; }
      if ($change =~ m/ø/) { $change =~ s/ø/o/g; }
      if ($change =~ m/ù/) { $change =~ s/ù/u/g; }
      if ($change =~ m/ú/) { $change =~ s/ú/u/g; }
      if ($change =~ m/û/) { $change =~ s/û/u/g; }
      if ($change =~ m/ü/) { $change =~ s/ü/u/g; }
      if ($change =~ m/ý/) { $change =~ s/ý/y/g; }
      print OUT "CHANGE $change ORIG $orig END\n";
    }

    if ($change =~ m/€/) { print OUT "MATCH  €\n"; }
    if ($change =~ m/ƒ/) { print OUT "MATCH  ƒ\n"; }
    if ($change =~ m/†/) { print OUT "MATCH  †\n"; }
    if ($change =~ m/‡/) { print OUT "MATCH  ‡\n"; }
    if ($change =~ m/‰/) { print OUT "MATCH  ‰\n"; }
    if ($change =~ m/•/) { print OUT "MATCH  •\n"; }
    if ($change =~ m/™/) { print OUT "MATCH  ™\n"; }
    if ($change =~ m/¡/) { print OUT "MATCH  ¡\n"; }
    if ($change =~ m/¢/) { print OUT "MATCH  ¢\n"; }
    if ($change =~ m/£/) { print OUT "MATCH  £\n"; }
    if ($change =~ m/¤/) { print OUT "MATCH  ¤\n"; }
    if ($change =~ m/¥/) { print OUT "MATCH  ¥\n"; }
    if ($change =~ m/¦/) { print OUT "MATCH  ¦\n"; }
    if ($change =~ m/§/) { print OUT "MATCH  §\n"; }
    if ($change =~ m/¨/) { print OUT "MATCH  ¨\n"; }
    if ($change =~ m/©/) { print OUT "MATCH  ©\n"; }
    if ($change =~ m/¬/) { print OUT "MATCH  ¬\n"; }
    if ($change =~ m/®/) { print OUT "MATCH  ®\n"; }
    if ($change =~ m/°/) { print OUT "MATCH  °\n"; }
    if ($change =~ m/²/) { print OUT "MATCH  ²\n"; }
    if ($change =~ m/³/) { print OUT "MATCH  ³\n"; }
    if ($change =~ m/´/) { print OUT "MATCH  ´\n"; }
    if ($change =~ m/µ/) { print OUT "MATCH  µ\n"; }
    if ($change =~ m/¶/) { print OUT "MATCH  ¶\n"; }
    if ($change =~ m/¹/) { print OUT "MATCH  ¹\n"; }
    if ($change =~ m/º/) { print OUT "MATCH  º\n"; }
    if ($change =~ m/¿/) { print OUT "MATCH  ¿\n"; }
    if ($change =~ m/þ/) { print OUT "MATCH  þ\n"; }
    if ($change =~ m/Þ/) { print OUT "MATCH  Þ\n"; }

    if ($change =~ m/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]/) { $change =~ s/[€ƒ†‡‰•™¡¢£¤¥¦§¨©¬®°²³´µ¶¹º¿þÞ]//g; 
      my $command = "UPDATE wpa_author_index SET wpa_author_index = '$change' WHERE wpa_author_index = '$orig'";
      print OUT "$command\n";
    }
    $orig = $change;					# orig has been changed to change
    if ($change =~ m/[‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý]/) {
      print OUT "TWO UPDATE $change\n";
    }
} } 



€	
ƒ	
†	
‡	
‰	
•	
™	
¡	
¢	
£	
¤	
¥	
¦	
§	
¨	
©	
¬	
®	
°	
²	
³	
´	
µ	
¶	
¹	
º	
¿	
þ	
Þ	

Ã¶	a
‚	,
„	"
…	...
ˆ	^
Š	S
‹	<
Œ	OE
Ž	Z
‘	'
’	'
“	"
”	"
—	-
˜	~
š	s
›	>
œ	oe
ž	z
Ÿ	y
ª	a
«	"
­	-
¯	-
±	+/-
·	-
»	"
¼	1/4
½	1/2
¾	3/4
À	A
Á	A
Â	A
Ã	A
Ä	A
Å	A
Æ	AE
Ç	C
È	E
É	E
Ê	E
Ë	E
Ì	I
Í	I
Î	I
Ï	I
Ð	D
Ñ	N
Ò	O
Ó	O
Ô	O
Õ	O
Ö	O
×	x
Ø	O
Ù	U
Ú	U
Û	U
Ü	U
Ý	Y
ß	B
à	a
á	a
â	a
ã	a
ä	a
å	a
æ	ae
ç	c
è	e
é	e
ê	e
ë	e
ì	i
í	i
î	i
ï	i
ð	o
ñ	n
ò	o
ó	o
ô	o
õ	o
ö	o
÷	/
ø	o
ù	u
ú	u
û	u
ü	u
ý	y

‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý
‚„…ˆŠ‹ŒŽ‘’“”—˜š›œžŸª«­¯±·»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüý

