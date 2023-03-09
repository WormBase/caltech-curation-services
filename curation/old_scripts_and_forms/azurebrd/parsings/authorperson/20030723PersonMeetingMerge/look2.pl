#!/usr/bin/perl

# find out people from Paul's and Eimear's list from IWM03
# (Paul's is attendees, Eimear's is abstracts), match them by
# last name, first name, to each other (paul's takes priority)
# and to postgres (two#).  if there's no match, email them.
# if there's a match and some info hasn't changed prior to 2002
# (when Cecilia started) then email them.  if match has all info
# from 2002 or later, don't email.  1013 have no match (email)
# 187 have match and have some old data (email) and 521 have 
# match with 2002+ data (no email).
#
# if ever want to resend this to everyone again, uncomment
# the &mailer(); call, and this time don't forget to send it
# (run it) from Cecilia's account, and cc: cecilia as well.
# 2003 07 31

use strict;
use diagnostics;
use Pg;

use Jex;	# mailer

my $conn = Pg::connectdb("dbname=testdb");
die $conn->errorMessage unless PGRES_CONNECTION_OK eq $conn->status;

# use cecilia's edited files (edited for typos compared to postgres)
my $paul = "/home/cecilia/work/Paul_Meeting_People/Paul_1580";
my $eimear = "/home/cecilia/work/Paul_Meeting_People/Eimear_3450";

my %pg;
my %paul;
my %eimear;

my %nomatch;
my %match;

my @two_tables = qw( two_firstname two_middlename two_lastname two_standardname
		     two_street two_city two_state two_post two_country 
		     two_mainphone two_labphone two_officephone two_otherphone 
		     two_fax two_email two_pis two_lab two_oldlab two_webpage );

&getFileData();
&getPgData();

# foreach my $pg_key (sort keys %pg) {
#   print "PG $pg_key $pg{$pg_key}\n";
# } # foreach my $pg_key (sort keys %pg)

&separateMatchAndNot();
&outputMatch();
&outputNomatch();

sub outputNomatch {
  my $match_file = 'nomatch';
  open (MAT, ">$match_file") or die "Cannot open $match_file : $!";
  foreach my $nomatch (sort keys %nomatch) {
    &dealNoMatch($nomatch);
#     my $num = keys %{ $pg{$nomatch} };
#     if ($num > 1) {
#       print MAT "MATCH\t$nomatch\n$nomatch{$nomatch}";
#       foreach my $pgnomatch (sort keys %{ $pg{$nomatch} }) { print MAT "\t$pgnomatch"; }
#       print MAT "\n\n";
#     }
  } # foreach my $match (sort keys %match)
  close (MAT) or die "Cannot close $match_file : $!";
} # sub outputNomatch

sub outputMatch {
  my $match_file = 'match';
  my $yes_file = 'yes';
  my $no_file = 'no';
  open (MAT, ">$match_file") or die "Cannot open $match_file : $!";
  open (YES, ">$yes_file") or die "Cannot open $yes_file : $!";
  open (NO, ">$no_file") or die "Cannot open $no_file : $!";
  foreach my $match (sort keys %match) {
    print MAT "MATCH\t$match";
    foreach my $pgmatch (sort keys %{ $pg{$match} }) { print MAT "\t$pgmatch"; }
    print MAT "\n$match{$match}";
    my ($yes_no, $body) = &checkTimestamps($match);
    print MAT "$body\n";
    if ($yes_no eq 'yes') { &dealYes($match{$match}, $body); } 
    if ($yes_no eq 'no') { print NO "$match{$match}$body\nDIVIDER\n\n"; }
#     foreach my $pgmatch (sort keys %{ $pg{$match} }) { &displayTwo($pgmatch); }
    print MAT "\nDIVIDER\n\n";
#     my $num = keys %{ $pg{$match} };
#     if ($num > 1) {
#       print MAT "MATCH\t$match\n$match{$match}";
#       foreach my $pgmatch (sort keys %{ $pg{$match} }) { print MAT "\t$pgmatch"; }
#       print MAT "\n\n";
#     }
  } # foreach my $match (sort keys %match)
  close (MAT) or die "Cannot close $match_file : $!";
  close (YES) or die "Cannot close $yes_file : $!";
  close (NO) or die "Cannot close $no_file : $!";
} # sub outputMatch

sub dealYes {
  my ($iwm, $two) = @_;
  my ($email) = $iwm =~ m/\nEmail:?\s+(.*)\n/;
  my ($name) = $two =~ m/\nStandard Name\s+(.*)\n/;
#   print YES "$name\t$email\n";
  my $user = 'cecilia@minerva.caltech.edu';
  my $subject = 'Updating WormBase Contact Information';
#   print YES "$iwm$two\nDIVIDER\n\n";
#   print YES "$match{$match}$body\nDIVIDER\n\n";
  my $body = "Dear $name:

I would like your help to update your personal information in WormBase
 (http://www.wormbase.org) because your WormBase information is old
or unverified and it could be out of date.

We've got this contact data information from the IWM2003:

$iwm

And this is your actual information in WormBase:

$two

Would you please verify which one is correct, or if one of them has 
never been correct, and send it back as an e-mail reply at your 
earliest convenience.  Feel free to add information or make 
corrections on the form below.

Please do not hesitate to contact me if you have any questions.

Best regards,

Cecilia

***** Personal Information Form *****
Last Name:
First Name:
Middle Name:
Standard_name:
Also_known_as:
CGC representative for Laboratory:
Lab (Two letter code or PI):
Mailing address:
street:
city:
state:
post code:
country:
Lab. phone number:
Off. phone number:
Fax:
E-mail:
Webpage:
Also published under these names:
***** END *****";
  print YES "$user\t$email\t$subject\t$body\n";
#   &mailer($user, $email, $subject, $body);
} # sub dealYes

sub dealNoMatch {
  my $nomatch = shift;
  my ($email) = $nomatch{$nomatch} =~ m/\nEmail:?\s+(.*)\n/;
  my ($last, $first) = $nomatch =~ m/^(.*) (.*?)$/g;
  my $name = ucfirst($first) . ' ' . ucfirst($last);
#   print MAT "$name\t$email\n";
#     print MAT "NOMATCH\t$nomatch\n$nomatch{$nomatch}";
#     foreach my $pgnomatch (sort keys %{ $pg{$nomatch} }) { print MAT "\t$pgnomatch"; }
#     print MAT "\n";

  my $user = 'cecilia@minerva.caltech.edu';
  my $subject = 'Updating WormBase Contact Information';
  my $body = "Dear $name:

I would like your help to update your personal information in WormBase
 (http://www.wormbase.org).

We've got this contact data information from the IWM2003:

$nomatch{$nomatch}

Would you please verify that it is correct as you would like it to
appear in WormBase, and send it back as an e-mail reply at your 
earliest convenience.  Feel free to add information or make 
corrections on the form below.

Please do not hesitate to contact me if you have any questions.

Best regards,

Cecilia

***** Personal Information Form *****
Last Name:
First Name:
Middle Name:
Standard_name:
Also_known_as:
CGC representative for Laboratory:
Lab (Two letter code or PI):
Mailing address:
street:
city:
state:
post code:
country:
Lab. phone number:
Off. phone number:
Fax:
E-mail:
Webpage:
Also published under these names:
***** END *****";
  print MAT "$user\t$email\t$subject\t$body\n";
#   &mailer($user, $email, $subject, $body);
} # sub dealNoMatch

sub checkTimestamps {
  my ($match) = shift;
  my $body = '';
  my $yes_no = 'no';
  foreach my $two_key (sort keys %{ $pg{$match} }) {
   
    $body .= "\n";
    foreach my $two_table (@two_tables) {
      my $result = $conn->exec( "SELECT * FROM $two_table WHERE joinkey = '$two_key' ORDER BY two_order;" );
      while (my @row = $result->fetchrow) {
        if ($row[1]) {
          my $two_temp = $two_table; $two_temp =~ s/two_//g;
          if ($two_temp eq 'pis') { $two_temp = 'Primary Investigator'; }
          if ($two_temp eq 'post') { $two_temp = 'Postal Code'; }
          if ($two_temp =~ m/phone/) { $two_temp =~ s/phone/ Phone/; }
          if ($two_temp =~ m/name/) { $two_temp =~ s/name/ Name/; }
          $two_temp = ucfirst($two_temp);
          $body .= "$two_temp\t$row[2]\n";
          unless ($row[3] =~ m/^200[23]/) { $yes_no = 'yes'; }
        } # if ($row[1])
      } # while (my @row = $result->fetchrow)
    } # foreach my $two_table (@two_tables)
  } # foreach my $two_key (sort keys %{ $pg{$match} })
  return ($yes_no, $body);
} # sub checkTimestamps

sub displayTwo {
  my ($two_key) = shift;
  print MAT "\n";
  foreach my $two_table (@two_tables) {
    my $result = $conn->exec( "SELECT * FROM $two_table WHERE joinkey = '$two_key' ORDER BY two_order;" );
    while (my @row = $result->fetchrow) {
      if ($row[1]) {
        my $two_temp = $two_table; $two_temp =~ s/two_//g;
        if ($two_temp eq 'pis') { $two_temp = 'Primary Investigator'; }
        if ($two_temp eq 'post') { $two_temp = 'Postal Code'; }
        if ($two_temp =~ m/phone/) { $two_temp =~ s/phone/ Phone/; }
        if ($two_temp =~ m/name/) { $two_temp =~ s/name/ Name/; }
        $two_temp = ucfirst($two_temp);
        print MAT "$two_temp\t$row[2]\t$row[3]\n";
#         print "<TR bgcolor='$blue'>\n  <TD>$two_table</TD>\n";
#         print "  <TD>$row[0]</TD>\n";
#         print "  <TD>$row[1]</TD>\n";
#         print "  <TD>$row[2]</TD>\n";
#         print "  <TD>$row[3]</TD>\n";
#         print "</TR>\n";
      } # if ($row[1])
    } # while (my @row = $result->fetchrow)
  } # foreach my $two_table (@two_tables)
} # sub displayTwo

sub separateMatchAndNot {
  # this block gets stuff that is totally new
  # check p & e vs pg
  my %pg_em;		# pg emails key email, value two number
  my $result = $conn->exec ( "SELECT * FROM two_email;" );
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[2] =~ s///g;
      $pg_em{$row[2]} = $row[0]; } }

  foreach my $p_last (sort keys %paul) {
    unless ($pg{$p_last}) { 
#       print "PAUL\t$p_last\t$paul{$p_last}\n"; 
#       &processPgWild($p_last);
#       my ($email) = $paul{$p_last} =~ m/Email: (.*)\n/;
#       if ($pg_em{$email}) {
#         $match{$p_last} = $pg_em{$email}; print "$p_last PAU EMAIL\t$email\t$pg_em{$email}\n"; }
#       else {
#         $nomatch{$p_last} = $paul{$p_last}; }
      $nomatch{$p_last} = $paul{$p_last}; 
    } else { 
      $match{$p_last} = $paul{$p_last};
    }
  } # foreach my $p_last (sort keys %paul)

  foreach my $e_last (sort keys %eimear) {
    if ($paul{$e_last}) { next; }		# skip if dealt with with paul's data
    unless ($pg{$e_last}) { 
#       print "EIM\t$e_last\t$eimear{$e_last}\n"; 
#       &processPgWild($e_last);
#       my ($email) = $eimear{$e_last} =~ m/Email\s+(.*)/;
#       if ($pg_em{$email}) {
#         $match{$e_last} = $pg_em{$email}; print "$e_last EIM EMAIL\t$email\t$pg_em{$email}\n"; }
#       else {
#         $nomatch{$e_last} = $eimear{$e_last}; }
      $nomatch{$e_last} = $eimear{$e_last};
if ($e_last =~ m/ntoine/) { print "$eimear{$e_last}\n$nomatch{$e_last}\n"; }
    } else { 
      $match{$e_last} = $eimear{$e_last};
    }
  } # foreach my $e_last (sort keys %eimear)
} # sub separateMatchAndNot



# # check p & e vs each other
# foreach my $e_last (sort keys %eimear) {
#   unless ($paul{$e_last}) { print "$e_last\t$eimear{$e_last}\n"; }
# }
# foreach my $p_last (sort keys %paul) {
#   unless ($eimear{$p_last}) { print "$p_last\t$paul{$p_last}\n"; }
# }




sub processPgWild {
  my $input_name = shift;
  my ($last_name) = $input_name =~ m/^(\S+)/g;
  my @people_ids;
  $last_name =~ s/\*/.*/g;
  $last_name =~ s/\?/./g;
  my @last_parts = split/\s+/, $last_name;
  my %last_parts;
  my %matches;                          # keys = wbid, value = amount of matches
  my %filter;
  foreach my $last_part (@last_parts) {
    my @tables = qw (first middle last);
    foreach my $table (@tables) {
      my $result = $conn->exec ( "SELECT * FROM two_aka_${table}name WHERE lower(two_aka_${table}name) ~ lower('$last_part');" );
      while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$last_part}++; }
      $result = $conn->exec ( "SELECT * FROM two_${table}name WHERE lower(two_${table}name) ~ lower('$last_part');" );
      while ( my @row = $result->fetchrow ) { $filter{$row[0]}{$last_part}++; }
    } # foreach my $table (@tables)
  } # foreach my $last_part (@last_parts)

  foreach my $number (sort keys %filter) {
    foreach my $last_part (@last_parts) {
      if ($filter{$number}{$last_part}) {
        my $temp = $number; $temp =~ s/two/WBPerson/g; $matches{$temp}++;
        my $count = length($last_part);
        unless ($last_parts{$temp} > $count) { $last_parts{$temp} = $count; }
      }
    } # foreach my $last_part (@last_parts)
  } # foreach my $number (sort keys %filter)

  foreach my $person (sort {$matches{$b}<=>$matches{$a} || $last_parts{$b} <=> $last_parts{$a}} keys %matches) {
    print "\t$person\thas $matches{$person} match(es)\tpriority $last_parts{$person}.\n";
  }
} # sub processPgWild


sub getPgData {
  my $result = $conn->exec( "SELECT * FROM two_firstname;");
  my %first; my %last; my %middle;
  my %aka_first; my %aka_last; my %aka_middle;
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      unless ($row[2]) { $row[2] = ''; }
      $row[0] =~ s///g; $row[2] =~ s///g;
      $first{$row[0]} = $row[2]; } }
  $result = $conn->exec( "SELECT * FROM two_lastname;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[2] =~ s///g;
      $last{$row[0]} = $row[2]; } }
  $result = $conn->exec( "SELECT * FROM two_middlename;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      unless ($row[2]) { $row[2] = ''; }
      $row[0] =~ s///g; $row[2] =~ s///g;
      $middle{$row[0]} = $row[2]; } }

  $result = $conn->exec( "SELECT * FROM two_aka_lastname;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[2] =~ s///g;
      unless ($row[2]) { $row[2] = ''; }
      $aka_last{$row[0]}{$row[1]} = $row[2]; } }
  $result = $conn->exec( "SELECT * FROM two_aka_firstname;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[2] =~ s///g;
      unless ($row[2]) { $row[2] = ''; }
      $aka_first{$row[0]}{$row[1]} = $row[2]; } }
  $result = $conn->exec( "SELECT * FROM two_aka_middlename;");
  while (my @row = $result->fetchrow) {
    if ($row[0]) { 
      $row[0] =~ s///g; $row[2] =~ s///g;
      unless ($row[2]) { $row[2] = ''; }
      $aka_middle{$row[0]}{$row[1]} = $row[2]; } } 

  foreach my $joinkey (sort keys %last) {
    unless ($first{$joinkey}) { $first{$joinkey} = ''; }
    unless ($middle{$joinkey}) { $middle{$joinkey} = ''; }
    my $key = "$last{$joinkey} $first{$joinkey}";
    $key = lc($key);
    $key =~ s/\.//g;
#     $pg{$key} = "$first{$joinkey} $middle{$joinkey} $last{$joinkey}";
    $pg{$key}{$joinkey}++;

    if ($aka_last{$joinkey}) {
      foreach my $order (sort keys %{ $aka_last{$joinkey} }) {
        unless ($aka_first{$joinkey}{$order}) { $aka_first{$joinkey}{$order} = ''; }
        unless ($aka_middle{$joinkey}{$order}) { $aka_middle{$joinkey}{$order} = ''; }
        my $key = "$aka_last{$joinkey}{$order} $aka_first{$joinkey}{$order}";
        $key = lc($key);
        $key =~ s/\.//g;
#         $pg{$key} = "$aka_first{$joinkey}{$order} $aka_middle{$joinkey}{$order} $aka_last{$joinkey}{$order}";
        $pg{$key}{$joinkey}++;
      } # foreach my $order (sort keys %{ $aka_last{$joinkey} })
    } # if ($aka_last{$joinkey})
  } # foreach my $joinkey (sort keys %last)
} # sub getPgData

sub getFileData {
  $/ = "";
  open (EIM, "<$eimear") or die "Cannot open $eimear : $!";
  while (my $entry = <EIM>) {
    $entry =~ s/\n+/\n/g;
    $entry =~ s/φ/o/g;
    $entry =~ s/ι/e/g;
    my ($first) = $entry =~ m/Presenter\t([ό\w\'\-]+)/g;
    my ($middle) = $entry =~ m/Presenter_Middle\t([\w\-]+)/g;
    my ($last) = $entry =~ m/Presenter_Last\t([ό\w\'\-\ ]+)/g;
    unless ($last) { $last = ''; }
    unless ($first) { $first = ''; }
    my $key = "$last $first";
    $key = lc($key);
#     $eimear{$key} = "$first $middle $last";
    $eimear{$key} = $entry;
  
  # used these 3 lines to check duplicates
  #   my $key = "$first $last";
  #   push @{ $eimear{$key}}, "$first $middle $last";
  
  } # while (<EIM>)
  close (EIM) or die "Cannot close $eimear : $!";
  
  # use this block to check duplicates
  # foreach my $e_key (sort keys %eimear) {
  #   if (scalar (@{ $eimear{$e_key}}) > 1) {
  #     foreach (@{ $eimear{$e_key}}) { print "$_\n"; }
  #   } # if (scalar (@{ $eimear{$e_key}}) > 1)
  # } # foreach my $e_key (sort keys %eimear)
  # my $num = scalar keys %eimear;
  # print "$num\n";
  
  
  open (PAU, "<$paul") or die "Cannot open $paul : $!";
  while (my $entry = <PAU>) {
    $entry =~ s/\n+/\n/g;
    my ($name, @stuff) = split/\n/, $entry;
    $name =~ s/,.*//g;
    $name =~ s/\.//g;
    $name =~ s/ Dr$//g;		# Take out suffix
    $name =~ s/ Mr$//g;		# Take out suffix
    $name =~ s/ Mrs$//g;		# Take out suffix
    $name =~ s/ Jr$//g;		# Take out suffix
    $name =~ s/ Sr$//g;		# Take out suffix
    $name =~ s/ III$//g;		# Take out suffix
    $name =~ s/ Ms$//g;		# Take out suffix
    $name =~ s/φ/o/g;
    $name =~ s/ι/e/g;
  # Ginger Ruth Kelly Miley may be last name Kelly Miley, but capturing Miley so
  # as not to capture Kelly from people named Kelly Lastname, also matches Eim file
    my ($last) = $name =~ m/(( Pires)?( Shmookler)?( Roy)?( Le)?( [dD][aei]l?)?( [vV][ao]n( [dD][ea][rnl])?)?( [a-z]+)? ([ό\w\'\-]+))$/;
    unless ($last) { $last = ''; }
    my ($first) = $name =~ m/^([ιό\w\'\-]+) /;
    if ($last =~ m/^\s+/) { $last =~ s/^\s+//g; }
#     $last =~ s/^\s+//g;
    my $key =  "$last $first";
    $key = lc($key);
#     $paul{$key} = $name;
    $paul{$key} = $entry;
  #   print "$name\n";
  } # while (<PAU>)
  close (PAU) or die "Cannot close $paul : $!";
  $/ = "\n";
  
} # sub getFileData

