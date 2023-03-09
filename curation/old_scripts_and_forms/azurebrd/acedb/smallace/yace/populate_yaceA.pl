#!/usr/bin/perl -w

# populate yace A db

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );
use Tie::IxHash;

my %eviTags;
$eviTags{"Paper_evidence"}++;
$eviTags{"Person_evidence"}++;
$eviTags{"Curator_confirmed"}++;
$eviTags{"Inferred_automatically"}++;
$eviTags{"RNAi_evidence"}++;
$eviTags{"Date_last_updated"}++;

my @infiles = <../dump*.ace>;
# my @infiles = <test*>;
my @objects;
my %hash;
my $count = 0;
foreach my $infile (@infiles) {
#   $count++; last if ($count > 1);
  $/ = "";
  open (IN, "<$infile") or die "Cannot open $infile : $!";
  while (my $entry = <IN>) { 
    chomp $entry; chomp $entry; 
    $entry =~ s/ -O "[\w\-\:]*"//g;		# strip timestamps
    push @objects, $entry; }
  close (IN) or die "Cannot close $infile : $!";
  $/ = "\n";
  print "F $infile \n";
} # foreach my $infile (@infiles)

while (my $object = shift @objects) {
  my $name;
  if ($object =~ m/^LongText/) {
    ($name) = $object =~ m/LongText : "([^"]*?)"/;
    my $go = 1;
    my $data = '';
    while ($go > 0) {
      my $line = shift @objects; 
      if ($line) { 
        if ($line eq '***LongTextEnd***') { $go = 0; }
          else { $data .= $line; } }
    } # while ($go > 0)
#     push @{ $hash{Paper}{$name}{abstract} }, $data;
    unless ($hash{Paper}{$name}{abstract}{$data}) {
      tie %{ $hash{Paper}{$name}{abstract}{$data} }, "Tie::IxHash"; }
#     $hash{Paper}{$name}{abstract}{$data}{""}{""} = 1;
#     print "N $name D $data\n";
  }  
  else {
    my @lines = split/\n/, $object;
    my $header = shift @lines;
    next unless ($header =~ m/^(\w+) : "([\w\.\: ]+)"/);
    my ($class, $name) = ($1, $2);
    next if ($class eq 'Phenotype_name');		# already in ?Phenotype as XREF
    next if ($class eq 'Gene_name');			# already in ?Gene as XREF
    foreach my $line (@lines) {
      if ($class eq 'RNAi') {
        if ($line =~ m/^Experiment\t /) { $line =~ s/^Experiment\t //; }
        if ($line =~ m/^Inhibits\t /) { $line =~ s/^Inhibits\t //; } }
      if ($class eq 'Phenotype') {
        if ($line =~ m/^Name\t /) { $line =~ s/^Name\t //; }
        if ($line =~ m/^Attribute_of\t /) { $line =~ s/^Attribute_of\t //; } }
      if ($class eq 'Paper') {
        if ($line =~ m/^Reference\t /) { $line =~ s/^Reference\t //; }
        if ($line =~ m/^Refers_to\t /) { $line =~ s/^Refers_to\t //; } }
      if ($class eq 'Gene') {
        if ($line =~ m/^Identity\t /) { $line =~ s/^Identity\t //; }
        if ($line =~ m/^Name /) { $line =~ s/^Name //; }
        if ($line =~ m/^Experimental_info\t /) { $line =~ s/^Experimental_info\t //; }
        if ($line =~ m/^Structured_description\t /) { $line =~ s/^Structured_description\t //; } }
      unless ( $line =~ m/^(\w+)\s+(.*?)$/) { print "ERR line does not match tag and data in $name : $line\n"; next; }
      my ($tag, $data) = $line =~ m/^(\w+)\s+(.*?)$/;
      next if ( ($tag eq 'Abstract') && ($class eq 'Paper') );
      if ($tag eq 'Evidence') { $data = qq($name $data); }
      foreach my $eviTag (sort keys %eviTags) {
        if ($data =~ m/($eviTag)\s+(.*)$/) { 		# DateType not bounded by doublequotes
          my $et = $1; my $ed = $2;
          if ($ed =~ m/^\"/) { $ed =~ s/^\"//; } if ($ed =~ m/\"$/) { $ed =~ s/\"$//; }
          $data =~ s/ ($eviTag)\s+(.*)$//; 
          if ($data =~ m/^\"/) { $data =~ s/^\"//; } if ($data =~ m/\"$/) { $data =~ s/\"$//; }
          unless ($hash{$class}{$name}{$tag}) { tie %{ $hash{$class}{$name}{$tag} }, "Tie::IxHash"; }
          $hash{$class}{$name}{$tag}{$data}{$et}{$ed}++;
        }
      } # foreach my $eviTag (sort keys %eviTags)
      my $order = 0;
      unless ($hash{$class}{$name}{$tag}) {
        tie %{ $hash{$class}{$name}{$tag} }, "Tie::IxHash"; }
      if ($data =~ m/^\"/) { $data =~ s/^\"//; } if ($data =~ m/\"$/) { $data =~ s/\"$//; }
      unless ($hash{$class}{$name}{$tag}{$data}) {
        tie %{ $hash{$class}{$name}{$tag}{$data} }, "Tie::IxHash"; }
#       $hash{$class}{$name}{$tag}{$data}{""}{""}++;
    } # foreach my $line (@lines)
  }  
} # while (my $object = shift @objects)


# Dump to text file
foreach my $class (sort keys %hash) {
  foreach my $name (sort keys %{ $hash{$class} }) {
    print "Class $class\tName $name\n";
    foreach my $tag (sort keys %{ $hash{$class}{$name} }) {
#       foreach my $data (sort { $hash{$class}{$name}{$tag}{$a}{order} <=> $hash{$class}{$name}{$tag}{$b}{order} } keys %{ $hash{$class}{$name}{$tag} }) {
      my $order = 0;
      foreach my $data (keys %{ $hash{$class}{$name}{$tag} }) {
        $order++;
        print "TAG $tag\tORDER $order\tDATA $data\n";
        foreach my $eviTag (sort keys %{ $hash{$class}{$name}{$tag}{$data} }) {
          foreach my $eviData (sort keys %{ $hash{$class}{$name}{$tag}{$data}{$eviTag} }) {
            print "TAG $tag\tORDER $order\tDATA $data\tEVI $eviTag\tED $eviData\n";
          } # foreach my $eviData (sort keys %{ $hash{$class}{$name}{$tag}{$data}{$eviTag} })
        } # foreach my $eviTag (sort keys %{ $hash{$class}{$name}{$tag}{$data} })
      } # foreach my $data (keys %{ $hash{$class}{$name}{$tag} })
    } # foreach my $tag (sort keys %{ $hash{$class}{$name} })
    print "\n";
  } # foreach my $name (sort keys %{ $hash{$class} })
} # foreach my $class (sort keys %hash)

__END__

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

my $result = $dbh->prepare( "SELECT * FROM two_comment" );
$result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
while (my @row = $result->fetchrow) {
  if ($row[0]) { 
    $row[0] =~ s///g;
    $row[1] =~ s///g;
    $row[2] =~ s///g;
    print "$row[0]\t$row[1]\t$row[2]\n";
  } # if ($row[0])
} # while (@row = $result->fetchrow)

__END__

  else {
    my @lines = split/\n/, $object;
    my $header = shift @lines;
    next unless ($header =~ m/^(\w+) : "(\w+)"/);
    my ($class, $name) = ($1, $2);
    foreach my $line (@lines) {
      if ($class eq 'Paper') {
        if ($line =~ m/^Reference\t /) { $line =~ s/^Reference\t //; } }
      if ($class eq 'Gene') {
        if ($line =~ m/^Experimental_info\t /) { $line =~ s/^Experimental_info\t //; }
        if ($line =~ m/^Structured_description\t /) { $line =~ s/^Structured_description\t //; } }
      unless ( $line =~ m/^(\w+)\s+(.*?)$/) { print "ERR line does not match tag and data in $name : $line\n"; next; }
      my ($tag, $data) = $line =~ m/^(\w+)\s+(.*?)$/;
      next if ( ($tag eq 'Abstract') && ($class eq 'Paper') );
      my $et = ''; my $ed = '';
#       foreach my $eviTag (sort keys %eviTags) {
# # DATA "WBRNAi00036549" Inferred_automatically "RNAi_primary" DATA
#         if ($data =~ m/($eviTag)\s+"([^\"]+)"$/) { 
#           $et = $1; $ed = $2;
#           $data =~ s/ ($eviTag)\s+"([^\"]+)"$//; 
# #           $hash{$class}{$name}{$tag}{$data}{evi}{$1}{$2}++;
# print "EH $name $tag DATA $data ONE $1 TWO $2\n";
#         }
#       } # foreach my $eviTag (sort keys %eviTags)
      my $order = 0;
print "START DATA $data TAG $tag LINE $line\n";
      unless ($hash{$class}{$name}{$tag}) { $hash{$class}{$name}{$tag}{$data}{order} = 1; }
       

#       if ($hash{$class}{$name}{$tag}) {
#           if ($hash{$class}{$name}{$tag}{$data}{order}) { $order = $hash{$class}{$name}{$tag}{$data}{order}; print "EXISTED "; }
#             else {
# foreach my $what (sort keys %{ $hash{$class}{$name}{$tag} }) { print "NEW DATA foreach $name T $tag W $what E\n"; }
# foreach my $what (sort keys %{ $hash{$class}{$name}{$tag} }) { 
#   foreach my $sw (sort keys %{ $hash{$class}{$name}{$tag}{$what} }) { 
#      print "NEW DATA foreach $name T $tag W $what WS $sw E\n"; } }
# ($order) = scalar keys %{ $hash{$class}{$name}{$tag} }; $order++; print "NEW DATA "; } }
#         else { $order++; print "NEW TAG "; }
print "D $data ORDER $order E\n";
      $hash{$class}{$name}{$tag}{$data}{order} = $order;
#       if ($et && $ed) { 
# print "D $data ORDER $order ET $et ED $ed\n";
# $hash{$class}{$name}{$tag}{$data}{evi}{$et}{$ed}++; }
#       push @{ $hash{$class}{$name}{$tag} }, $data;
    } # foreach my $line (@lines)
  }  
