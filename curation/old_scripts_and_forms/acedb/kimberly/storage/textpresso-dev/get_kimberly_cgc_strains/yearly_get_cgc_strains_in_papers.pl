#!/usr/bin/perl

# runs against all papers numerically following the last one logged in 'logfile', then adds date and new highest number.
# output in files with current date.html   2016 12 12

use strict;
use constant FILTERED => '0';

use LWP::Simple;
use lib "/usr/local/lib/textpresso/celegans/";
use TextpressoGeneralTasks;
use TextpressoDisplayTasks;

sub getSimpleDate {                     # begin getSimpleDate
  my $time = time;                      # set time
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) =
          localtime($time);             # get time
  my $sam = $mon+1;                     # get right month
  $year = 1900+$year;                   # get right year in 4 digit form
  if ($sam < 10) { $sam = "0$sam"; }    # add a zero if needed
  if ($mday < 10) { $mday = "0$mday"; } # add a zero if needed
  my $shortdate = "${year}${sam}${mday}";   # get final date
  return $shortdate;
} # sub getSimpleDate                   # end getSimpleDate

my $date = &getSimpleDate();

# no longer care about year for input, always run from last paper forward from logfile
# if (@ARGV < 1) {
#     die "Usage: $0 <year>\n";
# }
# my $year = $ARGV[0];

my %primaryPaps;
# my $primaryPaps = get "http://tazendra.caltech.edu/~postgres/cgi-bin/referenceform.cgi?pgcommand=SELECT+joinkey+FROM+pap_primary_data+WHERE+pap_primary_data+%3D+%27primary%27+AND+joinkey+IN+%28SELECT+joinkey+FROM+pap_year+WHERE+pap_year+%3D+%27$year%27%29&perpage=all&action=Pg+%21";
my $primaryPaps = get "http://tazendra.caltech.edu/~postgres/cgi-bin/referenceform.cgi?pgcommand=SELECT+*+FROM+pap_year+WHERE+joinkey+IN+%28SELECT+joinkey+FROM+pap_primary_data+WHERE+pap_primary_data+%3D+%27primary%27%29&perpage=all&action=Pg+%21";
my (@trtd) = split/<TR>/, $primaryPaps;
foreach my $line (@trtd) {
  my (@tds) = $line =~ m/<TD>(.*?)<\/TD>/g;
#   print qq(TD $tds[0] ONE $tds[1] E\n);
  $primaryPaps{papToYear}{$tds[0]} = $tds[1];
  $primaryPaps{yearToPap}{$tds[1]}{$tds[0]}++;
} # foreach my $line (@trtd)


# $/ = undef;
# my $logfile = '/home/azurebrd/work/get_kimberly_cgc_strains/logfile';
# open (IN, "<$logfile") or die "Cannot open $logfile : $!";
# my $logdata = <IN>;
# close (IN) or die "Cannot close $logfile : $!";
# $/ = "\n";
# my ($highestOld) = $logdata =~ m/WBPaper(\d+)/;
# print qq(HIGH $highestOld OLD\n);
my $highestOld = 0;


my $outsummaryfile = "yearly_summary_$date.html";

# my $outfile;
# my $outsummaryfile;
# if (FILTERED) {
#     $outfile = "strains_filtered_$date.html";
#     $outsummaryfile = "strains_summary_filtered_$date.html";
# }
# else {
# #     $outfile = "strains_$date.html";
# #     $outsummaryfile = "strains_summary_$date.html";
# }

my $proc_file_dir  = "/data2/data-processing/data/celegans/Data/processedfiles/";
my @fields = ("abstract", "introduction", "materials", "results", "discussion", "conclusion",
              "acknowledgments", "references", "body", "title");

my $cgc_name_location_file = "cgc_name_locations.txt";
my $cgc_strain_list_file   = "cgc_strains.txt";

my %years;
print "forming file list...\n";
my $year_dir = "$proc_file_dir/year";
my @year_files = <$year_dir/*>;
my %docid_list = ();
for my $year_file (@year_files) {
    open (Y, "<$year_file") or die $!;
    my $line = <Y>;
    chomp($line);
#     if ($line =~ /$year/) {
#         $docid_list{ filename($year_file) } = 1;
#     }
    my ($year) = $line =~ m/(\d{4})/;
    my $filename = filename($year_file);
    my ($papId) = $filename =~ m/(\d+)/;
    next unless ($papId > $highestOld);
    next unless ($primaryPaps{papToYear}{$papId});
    $docid_list{$papId} = $year;
#     print qq(LINE $papId YEAR $year E\n);
}
print "done.\n";

# get CGC stuff
print "loading CGC data... ";
my %cgc_name_locations = get_cgc_name_locations($cgc_name_location_file);
my %cgc_strains        = get_cgc_strains($cgc_strain_list_file);
$cgc_strains{'N2'}++;
print "done.\n";

my %result    = ();
my %strains   = ();
my %genotypes = ();
my %lines     = (); 
my %cgc_ack   = ();

my %docIds;
my %paperIds;
my %acknowledged;

for my $papid (sort {docidnum($a) <=> docidnum($b)} keys %docid_list) {
  my $docid = 'WBPaper' . $papid;
#   next unless ($docid =~ m/49122/);
#   next unless ($docid =~ m/490[0-5]/);
  print "processing $docid...\n";
  
  for my $field (@fields) {
    my $file = "$proc_file_dir/$field/$docid";
    next if (not -e $file);
    print "$field\n";
    
    open (IN, "<$file") or die $!;
    
    while (my $line = <IN>) {
      chomp($line);
      $line = TextpressoGeneralTasks::InverseReplaceSpecChar($line);
      $line =~ s/\\//g;
      
      # extract only the strains first
      while ($line =~ /\s+([A-Z]{1,3}\d{1,5})\s+/g) {
        my $strain_name = $1;
#         next if (not defined ( $cgc_name_locations{ lab_designation($strain_name) } ));
	next if ( not defined($cgc_strains{$strain_name}) ); 

        
        my $line_is_useful = 1;
        if (FILTERED) { $line_is_useful = is_useful($line); }
        
        if (defined( $strains{$docid}{$strain_name} )) {
          $strains{$docid}{$strain_name}++;
          $lines{$docid}{$strain_name}{$line} = 1 if ($line_is_useful);
        } else {
          $strains{$docid}{$strain_name} = 1;
          $lines{$docid}{$strain_name}{$line} = 1 if ($line_is_useful);
        }
      }
      
      # get the lines in which CGC is acknowledged
      if (is_ack_line($line)) {
      $cgc_ack{$docid}{$line} = 1;
      }
      
      # extract genotypes inside round brackets
      #while ($line =~ /\s+([A-Z]{2,3}\d+)\s+(\(.+?\))/g) {
      #    my $strain   = $1;
      #    my $genotype = $2;
      
      #    next if (not defined ( $cgc_name_locations{ lab_designation($strain) } ));
      
      #    # remove all the extra spaces introduced by textpresso tokenizer
      #    $genotype =~ s/\s?([^a-zA-Z0-9])\s?/$1/g;
      
      #    if (defined($genotypes{$strain}{$genotype})) {
      #        $genotypes{$strain}{$docid}{$genotype}++;
      #    } else { 
      #        $genotypes{$strain}{$docid}{$genotype} = 1;
      #    }
      #}
    }
  }
  close (IN);
}
print "\n\n";

my $line_separator = "<br>";

# print "Writing to output file...\n";
# open (OUT, ">$outfile") or die $!;
# print OUT "<html>";
# # my $summaryOutput;

my %summaryOutput;
my %countByYear;

for my $docid (sort keys %strains) {
    print "$docid\n";
    my ($paperid) = $docid =~ m/WBPaper(\d{8})/;
    my $outstring    = '';
    my $outsummary   = '';
    my $all_strains = join", ", sort keys %{ $strains{$docid} };
    my $acknowledged = 'NO';
    
    my $print_bib = 1;

    for my $strain (sort keys %{$strains{$docid}}) {

# skip if CGC does not have the strain
	if ( not defined($cgc_strains{$strain}) ) {
            #print "not in CGC: $strain\n";
            next;
        }
        if ($print_bib) { # prints only for the first time for each article
            $outstring .= "<b><font color=\"blue\">" . $docid . "</font></b>" . $line_separator;
            $outstring .= "Other doc IDs: " . get_bib_data($docid, "accession") . "$line_separator";
            $outstring .= "<b>Authors:</b> " . get_bib_data($docid, "author") . "$line_separator";
            $print_bib = 0;
        }

        $outstring .= $line_separator . "<b>Strain: <font color=\"red\">$strain</font></b>" . $line_separator;

        my $name_location = $cgc_name_locations{ lab_designation($strain) };
        #$outstring .= "<b>Name and location:</b> $name_location\n" . $line_separator;
    
        my @relevant_lines = keys %{$lines{$docid}{$strain}};
        if (@relevant_lines) {
            for my $relevant_line (@relevant_lines) {
                $relevant_line =~ s/$strain/\<font color=\"red\"\>$strain\<\/font\>/g;
                foreach my $other_strain (sort keys %{$strains{$docid}}) {
                   next if ($strain eq $other_strain);
                   $relevant_line =~ s/$other_strain/\<font color=\"#FFA233\"\>$other_strain\<\/font\>/g;
                }
                # $relevant_line =~ s/(\b[a-z]{3,4}-\d+\b)/\<font color=\"blue\"\>$1\<\/font\>/g;
                $outstring .= "<b>Sentence</b>: $relevant_line$line_separator";
            }
        } else {
            print "No relevant lines for $strain...\n";
        }
    }

    if (not $print_bib) {
        if (scalar (keys %{$cgc_ack{$docid}}) > 0) {
            $acknowledged = 'YES';
            $acknowledged{$paperid}++;
            $outstring .= $line_separator . "<b>CGC acknowledged</b>: YES$line_separator";
            for my $ack_line (keys %{$cgc_ack{$docid}}) {
                $outstring .= "<b>Sentence</b>: $ack_line$line_separator";
            }
        } else {
            $outstring .= $line_separator . "<b>CGC acknowledged</b>: NO$line_separator";
next; 	# for now skip NOs
        }   

        #$outstring .= "---------------------------------------------------------------$line_separator";
        $outstring .= "<hr/>$line_separator";
    }
#     print OUT "$outstring";
    my $year = $primaryPaps{papToYear}{$paperid};
    $countByYear{$year}++;
    $summaryOutput{$year} .= qq($year\t$docid\t$acknowledged\t$all_strains<br/>\n);
    $paperIds{$paperid}++;
    $docIds{$docid}++;
}

# my (@array) = sort keys %docIds;
# my $highestDocId = pop @array;
# print qq(HIGHEST $highestDocId HIGH\n);
# open (LOG, ">$logfile") or die "Cannot open $logfile : $!";
# print LOG qq($date\t$highestDocId\n$logdata);
# close (LOG) or die "Cannot close $logfile : $!";

open (OU2, ">$outsummaryfile") or die $!;
print OU2 "<html>";
my $ackCount   = scalar keys %acknowledged;
my $paperCount = scalar keys %paperIds;
my $papers = join", ", sort keys %paperIds;
my $docidCount = scalar keys %docIds;
my $docids = join", ", sort keys %docIds;
# print OU2 qq($ackCount acknowledgements in $paperCount papers in $docidCount documents<br/>\n);
foreach my $year (sort {$a<=>$b} keys %countByYear) {
  my $primaryYearCount = keys %{ $primaryPaps{yearToPap}{$year} };
  print OU2 qq($year - $countByYear{$year} out of $primaryYearCount primary papers<br/>\n);
}
print OU2 "<br/>\n";
# print OU2 qq(DOCIDS $docids<br/>\n);
# print OU2 qq(PAPERS $papers<br/>\n);
foreach my $year (sort {$b<=>$a} keys %summaryOutput) {
  print OU2 $summaryOutput{$year}; }

print OUT "</html>";
print OU2 "</html>";
close (OUT);
close (OU2);

print "\n\n";

# print "Strain & genotype list stored in $outfile in http://textpresso-dev.caltech.edu/strain/\n";

sub filename {
    my $fullname = shift;
    my @e = split(/\//, $fullname);
    my $filename = pop @e;
    return $filename;
}

sub get_bib_data {
    my $docid = shift;
    my $field = shift;

    my $file = "/data2/data-processing/data/celegans/Data/includes/$field/$docid";
    if (! -e $file) {
        warn "$file does not exist!\n";
        return;
    }

    undef($/);
    open (IN, "<$file") or die $!;
    my $authors = <IN>;
    close (IN);
    $/ = "\n";

    $authors =  TextpressoGeneralTasks::InverseReplaceSpecChar($authors);
    $authors =~ s/\\//g;
    return $authors;
}

sub lab_designation {
    my $string = shift;
    $string =~ /^([A-Z]+)/;
    return $1;
}

sub get_cgc_name_locations {
    my $file = shift;
    open (IN, "<$file") or die $!;
    my %hash;
    while (<IN>) {
        chomp;
        my ($designation, $name_location) = split(/\t/);
        $hash{$designation} = $name_location;
    }

    return %hash;
}

sub get_cgc_strains {
    my $file = shift;
    open (IN, "<$file") or die $!;
    my %hash;
    while (<IN>) {
        chomp;
        $hash{$_} = 1;
    }
    return %hash;
}

sub is_useful {
    my $line = shift;
    return 1 if (has_gene($line) && has_the_string_strain($line));
    return 0;
}


sub has_gene {
    my $line = shift;
    if ($line =~ /\b[a-z]{3,4}-\d+\b/) {
        return 1;
    }
    return 0;
}

sub has_the_string_strain {
    my $line = shift;
    if ($line =~ /strain/i) {
        return 1;
    }
    return 0;
}

sub docidnum {
    my $f = shift;
    $f =~ /WBPaper(\d+)/;
    return $1;
}

sub is_ack_line {
    my $line = shift;
    if ($line =~ /(CGC|Caenorhabditis Genetics? Cent(er|re)|C\s*.?\s*elegans Genetics? Cent(er|re)|Caenorhabditis elegans Genetics? Cent(er|re))/i) {
        if ($line =~ /(provid|obtain|thank|grateful|acknowledg|availab|genero|minnesota)/i) {
            return 1;
        }
    }

    return 0;
}
