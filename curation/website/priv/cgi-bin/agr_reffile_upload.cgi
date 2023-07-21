#!/usr/bin/env perl 

# upload reference files (paper documents) to ABC

# For Daniel to put files to upload in $path_to_files and upload all files by calling
# Valerio's bulk uploader on that path.  2023 07 21


use CGI;
use Fcntl;
use strict;
use Jex;
# use DBI;
use Dotenv -load => '/usr/lib/.env';

# my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 


my $query = new CGI;

my $path_to_files = '/usr/lib/blahblah/';

my $action;
unless ($action = $query->param('action')) {
  $action = 'none'; 
}

&printHeader('ABC Ref Files Upload');
&process();
&printFooter();


sub process {
  if ($action eq 'none') { &firstPage(); }
    elsif ($action eq 'Upload !') { &uploadFiles(); }
    elsif ($action eq 'Delete !') { &deleteFiles(); }
    else { print qq($action\n); }
} # sub process

sub uploadFiles {
  my $result = `ls`;
  print qq(upload : $result\n);
}

sub deleteFiles {
  my $result = `ls`;
  print qq(delete : $result\n);
}

sub firstPage {
  print "<FORM METHOD=\"POST\" ACTION=\"agr_reffile_upload.cgi\">";
  print "<TABLE>\n";
  print "<TR><TD ALIGN=\"right\">Upload all files from $path_to_files : </TD>";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Upload !\"></TD></TR>\n";
  print "<TR><TD ALIGN=\"right\">Delete all files from $path_to_files : </TD>";
  print "<TD><INPUT TYPE=\"submit\" NAME=\"action\" VALUE=\"Delete !\"></TD></TR>\n";
  print "<TR><TD ALIGN=\"right\">Link to reports : </TD>";
  print "<TD>Link goes here</TD></TR>\n";
  print "</TABLE>\n";
  print "</FORM>\n";
} # sub ChoosePhenotypeAssay



__END__

sub getTickets {
  &populateIntxn();
  my ($oop, $tickets) = &getHtmlVar($query, 'tickets');
  ($oop, my $curator) = &getHtmlVar($query, 'curator');
  unless ($curator) { print "ERROR : you must choose a curator name\n"; return; }
#   print "T $tickets T\n";
  for my $counter (1 .. $tickets) {
#     print "C $counter C\n";
    my ($ticket) = &getNewTicket();
    my $pad_ticket = &padZeros($ticket);
    print "COUNT $counter\tTICKET WBInteraction$pad_ticket\tCURATOR $curator\n";
    my $command = "INSERT INTO int_index VALUES ('$pad_ticket', '$ticket', '$curator');";
    my $result = $dbh->do( $command );
#     print "$command\n";
  }
} # sub getTickets

