#!/usr/bin/perl -w

use strict;
use LiteTemplate::Main;
use CGI::Carp qw(fatalsToBrowser);

## Open lite template.
my $template = LiteTemplate::Main->new();

## Add some extra things.
$template->add_page_title('OBO Foundry Ontologies');
$template->add_to_head('<meta name="description" content="The ontologies available from the Open Biomedical Ontologies project." />');
$template->add_data_title('Welcome to the OBO Foundry Ontologies');


## Open the output buffer.
my @buffer = ();


my $sortBy = "";

my @columns;
my $qstring = $ENV{"QUERY_STRING"};
my %filter;
$filter{show} = "ontologies";

my @array = ();
@array = split('&', $qstring) if $qstring;

foreach (@array){
  my ($a, $b) = split('=', $_);
  $filter{$a} = $b;
}

# add the suffix to the file name
my @input = readFile($filter{show}.'.txt');
die "No data in database: $!" if @input < 1;

my %data = ();
foreach (@input){
  my @lines = split('\n', $_);
  my $id = shift(@lines);
  $id =~ s/.*?\t//;
  foreach my $line (@lines) {
    my ($field, @txt) = split(/\t/, $line);

      # CJM: 20070602 : accept pipe-style and tab-style separator
      if (scalar(@txt) == 1 && $txt[0] =~ /(.*?)\|(.*)/) {
          # use a greedy match; PLO annoyingly has two entries

          # tab-style: home    http://obi.sourceforge.net/index.php    OBI Home
          # pipe-style: home    OBI Home|http://obi.sourceforge.net/index.php
          # (note the reversed order)
          @txt = ($2,$1);
      }

    if ( ! $txt[0] ) {
      $data{$id}{$field} = '';
    }
    else {
      $data{$id}{$field} = join("\t", @txt); 
    }
  }
  if ($data{$id}{download} =~
      m#http://obo.cvs.sourceforge.net/\*checkout\*/obo/obo/ontology/#){
    $data{$id}{cvs} = "yes";
  }else{
    $data{$id}{cvs} = "no";
  }
}

if (!exists $filter{sort}){
  $filter{sort} = "title";
}

my $idList = sortData(\%data, \%filter);

#my $string = '';
#foreach (@$idList){
#  $string .= "$_<br>";
#}
#$string .= "<br>sort criteria: $sortBy<br><br>";

my $coreOnly = 0;
$coreOnly = 1 if(exists $filter{foundry});

my $cvsOnly = 0;
$cvsOnly = 1 if(exists $filter{cvs});

my $sortable = '';
$sortable = '&amp;foundry=1' if $coreOnly;

## Add explanation.
#push @buffer, "<p>These are the prospective ontologies currently within OBO Foundry. Click on the column heading to sort the table and click on the ontology name for further information on the ontology.</p>";
#push @buffer, '<p>A subset of the OBO ontologies have the tag Member, while others are Candidates to the OBO Foundry. Membership indicates that the project developing and maintaining this ontology have voted to strive to adhere to the <a href="http://obofoundry.org/crit.shtml">principles</a> of the OBO Foundry. Candidacy indicates that the Foundry facilitors are actively in discussions with these projects to enlist their support and agreement.  A third category that is listed here, because they may be of interest are application ontologies. Lastly, some are list simply because they are a resource that may be of interest for future work in the community.</p>';
#push @buffer, '<p>Files tagged as <b>OBO CVS</b> are maintained in the OBO SourceForge CVS repository and are updated daily (where applicable).</p>';
#push @buffer, '<p><a href="http://www.bioontology.org/ncbo/faces/index.xhtml">BioPortal</a>.</p>';
#push @buffer, '<p><a href="http://www.ebi.ac.uk/ontology-lookup/">Ontology Lookup service</a>.</p>';
#push @buffer, '<p>For more details, see <a href="http://obofoundry.org/wiki/index.php/Mappings">Mappings</a> on the wiki.</p>';

#my $table_link = '<a href="http://www.obofoundry.org/index.cgi?foundry=1">Show only member OBO Foundry ontologies</a>';
#$table_link = '<a href="http://www.obofoundry.org/index.cgi">Show all ontologies</a>' if $coreOnly;


## Push the opening of the table onto the buffer.
#push @buffer, "<p class=\"centered_phrase\">$table_link</p>";
push @buffer, "<br />";
push @buffer, "<table class=\"themeTable\">";
push @buffer, " <tr>";
push @buffer, "  <th style=\"width: 30%\">";
push @buffer, "   <a href=\"http://www.obofoundry.org/index.cgi?sort=title$sortable&amp;show=$filter{show}\">Domain</a>";
push @buffer, "  </th>";
push @buffer, "  <th style=\"width: 10%\">";
push @buffer, "   <a href=\"http://www.obofoundry.org/index.cgi?sort=namespace$sortable&amp;show=$filter{show}\">Prefix</a>";
push @buffer, "  </th>";
push @buffer, "  <th style=\"width: 30%\">";
push @buffer, "   <a href=\"http://www.obofoundry.org/index.cgi?sort=download$sortable&amp;show=$filter{show}\">Files</a>";
push @buffer, "  </th>
";
push @buffer, "  <th style=\"width: 10%\">";
push @buffer, "   <a href=\"http://www.obofoundry.org/index.cgi?sort=format$sortable&amp;show=$filter{show}\">Format</a>";
push @buffer, "  </th>";
push @buffer, "  <th style=\"width: 10%\">";
push @buffer, "   <a href=\"http://www.obofoundry.org/index.cgi?sort=foundry$sortable&amp;show=$filter{show}\">Foundry</a>";
push @buffer, "  </th>";
push @buffer, "  <th style=\"width: 10%\">";
push @buffer, "   <a href=\"http://www.obofoundry.org/index.cgi?sort=cvs$sortable&amp;show=$filter{show}\">OBO CVS</a>
";
push @buffer, "  </th>";
push @buffer, " </tr>";


my $j = 0;
foreach my $id (@$idList){

  my $class = "oddRow";
  if ($j % 2 == 0){
    $class = "evenRow";
  }
  #$string .= "id = $id; j = $j; class = $class<br>";

  $j++;
  my @array = split(/\t/, $data{$id}{download});
  if ($array[1]) {
    $data{$id}{file} = "<a href=\"$array[0]\">$array[1]</a>";
  } else {
    if ($array[0]) 
    {
      my $label = $array[0];
      $label =~ s/\S+\/(\S+)$/$1/;
      $data{$id}{file} = "<a href=\"$array[0]\">$label</a>";
    } else {
      $data{$id}{file} = $data{$id}{download};
    }
  }


  my %row = (
	     class => $class,
	     title => $data{$id}{title},
	     namespace => $data{$id}{namespace},
	     file => $data{$id}{file},
	     id => $id,
	     foundry => $data{$id}{foundry},
	     cvs => $data{$id}{cvs}
	    );

  my $format_string = '';
  if($data{$id}{format} =~ /^go/){
    $format_string = '<a href="http://www.geneontology.org/GO.format.shtml#goflat" title="GO format guide">GO</a>';
  }elsif($data{$id}{format} =~ /^obo/){
    $format_string = '<a href="http://www.geneontology.org/GO.format.shtml#oboflat" title="OBO format guide">OBO</a>';
  }elsif($data{$id}{format} =~ /^owl/){
    $format_string = '<a href="http://www.w3.org/2004/OWL/" title="OWL format guide">OWL</a>';
  }elsif($data{$id}{format} =~ /xml|XML/){
    $format_string = '<a href="http://www.w3.org/XML/" title="XML format guide">XML</a>';
  }elsif($data{$id}{format} =~ /^protege/){
    $format_string = '<a href="http://protege.stanford.edu" title="Protege format guide">Protege</a>';
  }else{
    ($format_string = $data{$id}{format}) =~ s/(.*?)\t(.*)/<a href=\"$2\">$1<\/a>/;
  }

  ## Push the meat of the table onto the buffer.
  push @buffer, " <tr>";
  push @buffer, "  <td class=\"$row{class}\">";
  push @buffer, "   <a href=\"http://www.obofoundry.org/cgi-bin/detail.cgi?id=$row{id}\">$row{title}</a>";
  push @buffer, "  </td>";
  push @buffer, "  <td class=\"$row{class}\">";
  push @buffer, "   $row{namespace}";
  push @buffer, "  </td>";
  push @buffer, "  <td class=\"$row{class}\">";
  push @buffer, "   $row{file}";
  push @buffer, "  </td>";
  push @buffer, "  <td class=\"$row{class}\">";
  push @buffer, "   $format_string";
  push @buffer, "  </td>";
  push @buffer, "  <td class=\"$row{class}\">";
  push @buffer, "   $row{foundry}";
  push @buffer, "  </td>";
  push @buffer, "  <td class=\"$row{class}\">";
  push @buffer, "   $row{cvs}</td>";
  push @buffer, "  </tr>";
}
push @buffer, "</table>";


# ## Add side bar stuff. (Now done in SSI)
# $template->add_green_block('Alerts', 'alert.gif', 'Alerts about OBO Foundry',
# 			   'No alert is a good alert.');

## Finish.
$template->output(join('', @buffer));
exit(0);

##===subroutine zone===##

sub readFile
{	$/ = "\n\n";
	open(FH, $_[0]) or die "Can't open file $_[0]!";
	my @data = <FH>;
	close FH;
	chomp @data;
	return @data;
}

sub sortData{
  my $dataRef = shift;
  my $filterRef = shift;


  for ("foundry" || "cvs") {
    if ($filterRef->{$_}) {
      $dataRef = filterMe($dataRef, $_);
    }
  }

  my @ontList;
  if ($filterRef->{sort} ne "cvs") {
    @ontList = sort {
      lc($dataRef->{$a}{$filterRef->{sort}}) 
	cmp lc($dataRef->{$b}{$filterRef->{sort}})
      } keys %$dataRef;
  }else{
    my @listTwo;
    foreach my $ont (sort { 
      lc($dataRef->{$a}{title}) cmp 
	lc($dataRef->{$b}{title}) 
      } keys %$dataRef)
      {
	$dataRef->{$ont}{$filterRef->{sort}} eq "yes" ? 
	  push(@ontList, $ont) : 
	    push(@listTwo, $ont);
      }
    push(@ontList, @listTwo);
  }
  return \@ontList;
}

sub filterMe{

  my $data = shift;
  my $crit = shift;
  if ($crit eq "cvs") {
    foreach my $ont (keys %$data){
      if ($data->{$ont}{$crit} eq "no"){
	delete $data->{$ont};
      }
    }
  } elsif ($crit eq "foundry") {
    foreach my $ont (keys %$data) {
      #delete $data->{$ont} if ($data->{$ont}{$crit} !~ /active|candidate/);
      delete $data->{$ont} if ($data->{$ont}{$crit} !~ /active|candidate|yes/);
    }
  }
  return $data;
}
