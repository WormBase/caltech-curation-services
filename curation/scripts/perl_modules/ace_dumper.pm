package ace_dumper;
require Exporter;

# use LWP::Simple;
# use Mail::Mailer;
use Encode qw( from_to is_utf8 decode);
use HTML::Entities;
use DBI;
use Dotenv -load => '/usr/lib/.env';
  use open qw(:std :utf8);


our @ISA	= qw(Exporter);
our @EXPORT	= qw( utf8ToHtml utf8ToHtmlWithoutDecode filterAce populateSimpleRemap filterSimpleCharacters populateDeadObjects );

our $VERSION	= 1.00;

# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $dbh = DBI->connect ( "dbi:Pg:dbname=$ENV{PSQL_DATABASE};host=$ENV{PSQL_HOST};port=$ENV{PSQL_PORT}", "$ENV{PSQL_USERNAME}", "$ENV{PSQL_PASSWORD}") or die "Cannot connect to database!\n";
# my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb;host=tazendra.caltech.edu;port=$ENV{PSQL_PORT}", "acedb", "") or die "Cannot connect to database!\n";
my $result;


sub utf8ToHtml {
  my ($simpleRemapHashRef, $value) = @_;
#   my $return = encode_entities(decode('utf-8', $value));	# on tazendra needed to decode sometimes, on cervino we just encode 2023 02 16
  my $return = encode_entities($value);
  ($return) = &filterSimpleCharacters($simpleRemapHashRef, $return);
  $return =~ s/^\s+//; $return =~ s/\s+$//;
  return $return;
} # sub utf8ToHtml

sub utf8ToHtmlWithoutDecode {
  my ($simpleRemapHashRef, $value) = @_;
  my $return = encode_entities($value);
  ($return) = &filterSimpleCharacters($simpleRemapHashRef, $return);
  $return =~ s/^\s+//; $return =~ s/\s+$//;
  return $return;
} # sub utf8ToHtml

sub filterAce {
  my $data = shift;
  if ($data =~ m/\//) { $data =~ s/\//\\\//g; }
  if ($data =~ m/\"/) { $data =~ s/\"/\\\"/g; }
  return $data;
}

sub populateSimpleRemap {
  my %simpleRemap;
  $simpleRemap{"&#x2010;"} = '-';
  $simpleRemap{"&ndash;"} = '-';
  $simpleRemap{"&mdash;"} = '-';
  $simpleRemap{"&quot;"} = '"';
  $simpleRemap{"&ldquo;"} = '"';
  $simpleRemap{"&rdquo;"} = '"';
  $simpleRemap{"&lsquo;"} = "'";
  $simpleRemap{"&rsquo;"} = "'";
  $simpleRemap{"&prime;"} = "'";
  $simpleRemap{"&#39;"} = "'";
  $simpleRemap{"&lt;"} = "<";
  $simpleRemap{"&gt;"} = ">";
  $simpleRemap{"&nbsp;"} = " ";
  return \%simpleRemap;
} # sub populateSimpleRemap

sub filterSimpleCharacters {
  my ($simpleRemapHashRef, $value) = @_;
  my %simpleRemap = %$simpleRemapHashRef;
  if ($value =~ m/&\S+;/) {
    foreach my $htmlChar (sort keys %simpleRemap) {
      my $simpleChar = $simpleRemap{$htmlChar};
      if ($value =~ m/$htmlChar/) { $value =~ s/$htmlChar/$simpleChar/g; }
    }
  }
  return $value;
}


sub populateDeadObjects {
  my %deadObjects;
  $result = $dbh->prepare( "SELECT * FROM pap_status WHERE pap_status = 'invalid';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{paper}{"WBPaper$row[0]"} = $row[1]; }
  $result = $dbh->prepare( "SELECT * FROM obo_data_anatomy WHERE obo_data_anatomy ~ 'is_obsolete: true';" ); $result->execute();
  while (my @row = $result->fetchrow) { $deadObjects{anatomy}{"$row[0]"} = $row[0]; }

  my %temp;
  $result = $dbh->prepare( "SELECT * FROM gin_dead;" ); $result->execute();
  while (my @row = $result->fetchrow) {                 # Chris sets precedence of split before merged before suppressed before dead, and a gene can only have one value, referring to the highest priority (only 1 value per gene in gin_dead table)  2013 10 21
    if ($row[1] =~ m/split_into (WBGene\d+)/) {       $temp{"split"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/merged_into (WBGene\d+)/) { $temp{"mapto"}{"WBGene$row[0]"} = $1; }
      elsif ($row[1] =~ m/Suppressed/) {              $temp{"suppressed"}{"WBGene$row[0]"} = $row[1]; }
      elsif ($row[1] =~ m/Dead/) {                    $temp{"dead"}{"WBGene$row[0]"} = $row[1]; } }
  my $doAgain = 1;                                    # if a mapped gene maps to another gene, loop through all again
  while ($doAgain > 0) {
    $doAgain = 0;                                     # stop if no genes map to other genes
    foreach my $gene (sort keys %{ $temp{mapto} }) {
      next unless ( $temp{mapTo}{$gene} );
      my $mappedGene = $temp{mapTo}{$gene};
      if ($temp{mapTo}{$mappedGene}) {
        $temp{mapTo}{$gene} = $temp{mapTo}{$mappedGene};          # set mapping of original gene to 2nd degree mapped gene
        $doAgain++; } } }                             # loop again in case a mapped gene maps to yet another gene
  foreach my $type (sort keys %temp) {
    foreach my $gene (sort keys %{ $temp{$type} }) {
      my $value = $temp{$type}{$gene};
      $deadObjects{gene}{$gene}{$type} = $value; } }
  return \%deadObjects;
} # sub populateDeadObjects



1;
