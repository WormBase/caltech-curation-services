#!/usr/bin/perl -w

# Display svm results

# Look at caprica's <dates>/ directories and get paper-type-result mappings.  
# Sparked by Karen's frustration without her request.  2011 04 14
# 
# Form redone to store svm values locally in postgres.  For Kimberly and Daniela.
# 2012 07 02


use strict;
use CGI;
use DBI;
use Jex;
use LWP::Simple;
use Tie::IxHash;                                # allow hashes ordered by item added
use POSIX qw(ceil);

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n";
my $result;

my $query = new CGI;
my $oop;

my $frontpage = 1;

my %datatypes;			# allowed datatypes from the cur_datatype column from the cur_result postgres table
my %chosenDatatypes;		# selected datatypes to display
my %datesSvm; 			# existing dates svm was processed $datesSvm{$date}++
my %chosenDatesSvm;		# selected dates dates to display
my %chosenPapers;		# selected papers to display
my %oaData;			# curator PG data from OA or other pg tables
my %curData;			# curator PG data from cur_curdata table
my %cfp;			# curator FP results from cfp_ tables
my %afp;			# author FP results from afp_ tables
my %journal;			# pap_journal key is paper joinkey
my %pmid;			# link to ncbi from pap_identifier
my %pdf;			# link to pdf on tazendra from pap_electronic_path
my %primaryData;		# primary or not from pap_primary
my %svmData; 			# $svmData{$joinkey}{$modifier}{$datatype}{$date} = $result;
my %svmPos;			# joinkey is svm positive
my %svmNeg;			# joinkey is svm negative
my %doneYes;			# joinkey has been curated
my %doneNo;			# joinkey has not been curated
my %curators;		tie %curators, "Tie::IxHash";			# $curators{"two1823"}  = "Juancarlos Chan";
my %posNegOptions;	tie %posNegOptions, "Tie::IxHash";		# $posNegOptions{"pgvalue"} = "displayValue"
my %premadeComments;	tie %premadeComments, "Tie::IxHash";		# $premadeComments{"pgvalue"} = "displayValue"

my $tdDot = qq(<td align="center" style="border-style: dotted">);
my $thDot = qq(<th align="center" style="border-style: dotted">);

&display();



sub display {
  my $action; my $normal_header_flag = 1;
  &printHeader('SVM summary');
  &populateDatatypes();
  &populateDatesSvm();
  &populateCurators();
  &populatePremadeComments(); 
  &populatePosNegOptions(); 
  unless ($action = $query->param('action')) {
    $action = 'none';
    if ($frontpage) { &firstPage(); }
  } else { $frontpage = 0; }

  &printFrontPageLink($action);

  if ($action eq 'Get Results') { &getResults(); }
  elsif ($action eq 'Add Results') { &addResults(); }
  elsif ($action eq 'Overwrite Selected Results') { &overwriteSelectedResults(); }
  elsif ($action eq 'SVM Prediction Page') { &printSvmPredictionsPage(); }
  elsif ($action eq 'SVM Analysis Page') { &printSvmResultsPage(); }
  elsif ($action eq 'Specific Paper Page') { &printSpecificPaperPage(); }
  elsif ($action eq 'Add Results Page') { &printAddResultsPage(); }

  &printFooter();
}

sub printFormOpen { print qq(<form name='form1' method="post" action="svm_results.cgi">\n); }
sub printFormClose { print qq(</form>\n); }

sub printFrontPageLink { 
  my ($action) = @_;
  if ($action ne 'none') {
    print qq(<b>$action</b> <a href="svm_results.cgi">Back to Main Page</a><br />\n); }
} # sub printFrontPageLink

sub firstPage {
  print "Display of data from date directories from postgres table cur_svmdata<br /><br />\n";
  &printFormOpen();
  print qq(<table border="0">\n);
  print qq(<tr><td>View SVM Predictions for Curation</td>\n);
  print qq(<td><input type="submit" name="action" value="SVM Prediction Page"></td></tr>\n);
  print qq(<tr><td>Analyze SVM Results</td>\n);
  print qq(<td><input type="submit" name="action" value="SVM Analysis Page"></td></tr>\n);
  print qq(<tr><td>Check Specific Paper</td>\n);
  print qq(<td><input type="submit" name="action" value="Specific Paper Page"></td></tr>\n);
  print qq(<tr><td>Enter Curator Results</td>\n);
  print qq(<td><input type="submit" name="action" value="Add Results Page"></td></tr>\n);
  print qq(</table>\n);
  &printFormClose();
} # sub firstPage

sub printSpecificPaperPage {
  &printFormOpen();
  &printTextareaSpecificPapers();
  &printCheckboxesDatatype();
  &printCheckboxesCurationSources();
  &printPaperOptions();
  &printSubmitGetResults();
  &printFormClose();
} # sub printSpecificPaperPage

sub printSvmPredictionsPage {
  &printFormOpen();
  &printCheckboxesDatatype();
  &printCheckboxesSvmPredictionsCuratedStatus(); 
  &printSelectSvmDates(); 
  &printCheckboxesCurationSources();
  &printPaperOptions();
  &printSubmitGetResults();
  &printFormClose();
} # sub printSvmPredictionsPage

sub printSvmResultsPage {
  &printFormOpen();
  &printCheckboxesDatatype();
  &printCheckboxesSvmResults(); 
  &printSelectSvmDates(); 
  &printCheckboxesCurationSources();
  &printPaperOptions();
  &printSubmitGetResults();
  &printFormClose();
} # sub printSvmResultsPage

sub printAddResultsPage {
  &printFormOpen();
  &printAddSection();
  &printFormClose();
} # sub printAddResultsPage


sub printCheckboxesDatatype {
  print qq(<br/>);
  print qq(svm datatypes :<br/>\n);
  foreach my $datatype (sort keys %datatypes) { 
    print qq(<input type="checkbox" name="checkbox_$datatype" value="$datatype">$datatype<br/>\n);
  } # foreach my $datatype (sort keys %datatypes) 
  print qq(<br/>);
} # sub printCheckboxesDatatype

sub printCheckboxesSvmPredictionsCuratedStatus {
  print qq(svm prediction :<br/>);
  print qq(<input type="checkbox" name="checkbox_svmpos" checked="checked">svm positive<br/>\n);
  print qq(<input type="checkbox" name="checkbox_svmneg" >svm negative<br/>\n);
  print qq(<br/>);
  print qq(curated status :<br/>);
  print qq(<input type="checkbox" name="checkbox_doneyes" >yes curated<br/>\n);
  print qq(<input type="checkbox" name="checkbox_doneno"  checked="checked">not curated<br/>\n);
  print qq(<br/>);
} # sub printCheckboxesSvmPredictionsCuratedStatus

#   print qq(curator result :<br/>);
#   print qq(<input type="checkbox" name="checkbox_curpos" checked="checked">curator positive<br/>\n);
#   print qq(<input type="checkbox" name="checkbox_curneg" >curator negative<br/>\n);
#   print qq(<br/>);

sub printCheckboxesSvmResults {
  print qq(svm result :<br/>);
  print qq(<input type="checkbox" name="checkbox_truepos"  >true positive<br/>\n);
  print qq(<input type="checkbox" name="checkbox_trueneg"  >true negative<br/>\n);
  print qq(<input type="checkbox" name="checkbox_falsepos" >false positive<br/>\n);
  print qq(<input type="checkbox" name="checkbox_falseneg" >false negative<br/>\n);
  print qq(<br/>);
} # sub printCheckboxesSvmResults

sub printSelectSvmDates {
  print qq(svm dates :<br/>);
  print qq(<select name="select_datesSvm" multiple="multiple" size="8">);
  print qq(<option value="all" selected="selected">all</option>\n);
  foreach my $dateSvm (reverse sort keys %datesSvm) { print qq(<option>$dateSvm</option>\n); }
  print qq(</select><br/>);
  print qq(<br/>);
} # sub printSelectSvmDates

sub printCheckboxesCurationSources {
  print qq(curation sources :<br/>\n);
  print qq(<input type="checkbox" name="checkbox_oa"  checked="checked">OA or other postgres<br/>\n);
  print qq(<input type="checkbox" name="checkbox_cur" checked="checked">Curator uploaded cur_curdata<br/>\n);
  print qq(<input type="checkbox" name="checkbox_cfp"   >curator first pass cfp_<br/>\n);
  print qq(<input type="checkbox" name="checkbox_afp"   >author first pass afp_<br/>\n);
  print qq(<input type="checkbox" name="checkbox_random">random positive or negative<br/>\n);
  print qq(<br/>);
} # sub printCheckboxesCurationSources

sub printPaperOptions {
  print qq(papers per page <input name="papers_per_page" value="10"><br/>\n);
  print qq(<input type="checkbox" name="checkbox_journal" checked="checked">show journal<br/>\n);
  print qq(<input type="checkbox" name="checkbox_pmid"    checked="checked">show pmid<br/>\n);
  print qq(<input type="checkbox" name="checkbox_pdf"     checked="checked">show pdf<br/>\n);
  print qq(<input type="checkbox" name="checkbox_primary" checked="checked">show pap_primary_data<br/>\n);
  print qq(<br/>);
} # sub printPaperOptions

sub printTextareaSpecificPapers {
  print qq(get specific papers (enter in format WBPaper00001234)<br/>);
  print qq(<textarea rows="4" cols="80" name="specific_papers"></textarea><br/>\n);
  print qq(<br/>);
} # sub printTextareaSpecificPapers

sub printSubmitGetResults {
  print qq(<input type="submit" name="action" value="Get Results"><br/>\n);
} # sub printSubmitGetResults


sub printAddSection {
  my ($twonumForm, $datatypeForm, $posNegForm, $paperResultsForm, $commentForm) = @_;
  my $selected = '';
  &printFormOpen();
  print qq(Select your curator name :<br/>);
  print qq(<select name="select_curator">);
  print qq(<option value=""             ></option>\n);
  foreach my $twonum (keys %curators) { 
    if ($twonum eq $twonumForm) { $selected = qq(selected="selected"); } else { $selected = ''; }
    print qq(<option value="$twonum" $selected>$curators{$twonum}</option>\n); }
  print qq(</select><br/>);
  print qq(Select your datatype :<br/>);
  print qq(<select name="select_datatype">);
  print qq(<option value=""             ></option>\n);
  foreach my $datatype (sort keys %datatypes) {
    if ($datatype eq $datatypeForm) { $selected = qq(selected="selected"); } else { $selected = ''; }
    print qq(<option value="$datatype" $selected>$datatype</option>\n); }
  print qq(</select><br/>);
  print qq(Select if the data is positive or negative :<br/>);
  print qq(<select name="select_pos_or_neg" size="2">);
  foreach my $posNegValue (keys %posNegOptions) {
    if ($posNegForm eq $posNegValue) { $selected = qq(selected="selected"); } else { $selected = ''; }
    print qq(<option value="$posNegValue" $selected>$posNegOptions{$posNegValue}</option>\n); }
  print qq(</select><br/>);
  print qq(Enter paper data here in the format "WBPaper00001234" or "WBPaper00001234.sup.1" with separate papers in separate lines.<br/>);
  print qq(<textarea name="textarea_paper_results" rows="6" cols="80">$paperResultsForm</textarea><br/>\n);
  print qq(Select your comment :<br/>);
  print qq(<select name="select_comment">);
  print qq(<option value=""             ></option>\n);
  foreach my $comment (keys %premadeComments) { 
    if ($comment eq $commentForm) { $selected = qq(selected="selected"); } else { $selected = ''; }
    print qq(<option value="$comment" $selected>$premadeComments{$comment}</option>\n); }
  print qq(</select><br/>);
  print qq(<input type="submit" name="action" value="Add Results"><br/>\n);
  &printFormClose();
} # sub printAddSection

sub addResults {
  &printFormOpen();
  my $errorData = '';
  my %papersToAdd;
  ($oop, my $twonum) = &getHtmlVar($query, "select_curator");
  unless ($twonum) { $errorData .= "Error : Need to select a curator.<br/>\n"; }
  ($oop, my $datatype) = &getHtmlVar($query, "select_datatype");
  unless ($datatype) { $errorData .= "Error : Need to select a datatype.<br/>\n"; }
  ($oop, my $posNeg) = &getHtmlVar($query, "select_pos_or_neg");
  unless ($posNeg) { $errorData .= "Error : Need to select whether result is positive or negative.<br/>\n"; }
  ($oop, my $paperResults) = &getHtmlVar($query, "textarea_paper_results");
  if ($paperResults) {
      my @lines = split/\r\n/, $paperResults;
      foreach my $line (@lines) {
        if ($line =~ m/^(WBPaper\S+)$/) {
            my $paper = $1;
            my ($joinkey, $paperModifier) = ('', 'main');
            if ($paper =~ m/^WBPaper(\d+)\.(.*)$/) { $joinkey = $1; $paperModifier = $2; }
              elsif ($paper =~ m/^WBPaper(\d+)$/) { $joinkey = $1; }
              else { $errorData .= "Error : not a paper nor paper.something : ${paper}<br/>\n"; }
            $papersToAdd{$joinkey}{$paperModifier}++; }
         else { $errorData .= qq(Error bad line : ${line}<br/>\n); }
      } } # foreach my $line (@lines)
    else { $errorData .= "Error : Need to enter at least one paper.<br/>\n"; }
  ($oop, my $comment) = &getHtmlVar($query, "select_comment");
  if ($errorData) { 				# problem with data, do not allow creation of any data, show form again
      print "$errorData<br />\n"; 
      printAddSection($twonum, $datatype, $posNeg, $paperResults, $comment); }
    else {					# all data is okay, enter data.
      my %pgData;
      my $joinkeys = join"','", sort keys %papersToAdd;
      $result = $dbh->prepare( "SELECT * FROM cur_curdata WHERE cur_datatype = '$datatype' AND cur_paper IN ('$joinkeys')" );
      $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
      while (my @row = $result->fetchrow) {
        $pgData{$row[0]}{$row[1]}{$row[2]}{$row[3]}{posneg}    = $row[4]; 
        $pgData{$row[0]}{$row[1]}{$row[2]}{$row[3]}{comment}   = $row[5];
        $pgData{$row[0]}{$row[1]}{$row[2]}{$row[3]}{timestamp} = $row[6]; }
      my @data; my @duplicateData;
      foreach my $joinkey (sort keys %papersToAdd) {
        foreach my $modifier (sort keys %{ $papersToAdd{$joinkey} }) {
          my @line; 
          push @line, $joinkey;
          push @line, $modifier;
          push @line, $datatype;
          push @line, $twonum;
          push @line, $posNeg;
          push @line, $comment;
          if ($pgData{$joinkey}{$modifier}{$datatype}{$twonum}) { push @duplicateData, \@line; }
            else { push @data, \@line; }
        } # foreach my $paperMod (sort keys %{ $papersToAdd{$joinkey} })
      } # foreach my $joinkey (sort keys %papersToAdd)
      print qq(<table border="1">\n);
      foreach my $lineRef (@data) {
        my @line = @$lineRef;
        my $pgcommand = join"','", @line;
        $pgcommand = "INSERT INTO cur_curdata VALUES ('$pgcommand')";
        print "$pgcommand<br/>\n";
# UNCOMMENT TO POPULATE
        $dbh->do( $pgcommand );
        my $trData = join"</td>$tdDot", @line;
        print qq(<tr>${tdDot}$trData</td></tr>\n);
      } # foreach my $lineRef (@data)
      print qq(</table>\n);
      if (scalar @data > 0) { print "results added<br />\n"; }

      my $overwriteCount = 0;
      foreach my $lineRef (@duplicateData) {		# for data already in postgres, add option to overwrite
        $overwriteCount++;
        my @line = @$lineRef;
        my ( $joinkey, $modifier, $datatype, $twonum, $posNeg, $comment ) = @line;
        my $posnegPg    = $pgData{$joinkey}{$modifier}{$datatype}{$twonum}{posneg};
        my $commentPg   = $pgData{$joinkey}{$modifier}{$datatype}{$twonum}{comment};
        my $timestampPg = $pgData{$joinkey}{$modifier}{$datatype}{$twonum}{timestamp};
        print qq(<input type="hidden" name="joinkey_$overwriteCount"  value="$joinkey"  >);
        print qq(<input type="hidden" name="modifier_$overwriteCount" value="$modifier" >);
        print qq(<input type="hidden" name="datatype_$overwriteCount" value="$datatype" >);
        print qq(<input type="hidden" name="twonum_$overwriteCount"   value="$twonum"   >);
        print qq(<input type="hidden" name="posneg_$overwriteCount"   value="$posNeg"   >);
        print qq(<input type="hidden" name="comment_$overwriteCount"  value="$comment"  >);
        print qq(WBPaper$joinkey $modifier $datatype $curators{$twonum} ALREADY in postgres with value "$posnegPg" and comment "$premadeComments{$commentPg}" at $timestampPg.  Replace with new value $posNeg and comment "$premadeComments{$comment}" ?\n);
        print qq(<input type="checkbox" name="checkbox_$overwriteCount" value="overwrite"><br/>\n);
      } # foreach my $lineRef (@data)
      if ($overwriteCount > 0) {
        print qq(<input type="hidden" name="overwrite_count" value="$overwriteCount">);
        print qq(<input type="submit" name="action" value="Overwrite Selected Results"><br/>\n); }
#  cur_paper | cur_paper_modifier | cur_datatype | cur_curator | cur_curdata | cur_comment | cur_timestamp 
    } # else # if ($errorData)
  &printFormClose();
} # sub addResults

sub overwriteSelectedResults { 
  ($oop, my $overwriteCount) = &getHtmlVar($query, "overwrite_count");
  my @pgcommands;
  for my $i (1 .. $overwriteCount) {
    ($oop, my $overwrite) = &getHtmlVar($query, "checkbox_$i");
    next unless ($overwrite eq 'overwrite');
    ($oop, my $joinkey ) = &getHtmlVar($query, "joinkey_$i");
    ($oop, my $modifier) = &getHtmlVar($query, "modifier_$i");
    ($oop, my $datatype) = &getHtmlVar($query, "datatype_$i");
    ($oop, my $twonum  ) = &getHtmlVar($query, "twonum_$i");
    ($oop, my $posNeg  ) = &getHtmlVar($query, "posneg_$i");
    ($oop, my $comment ) = &getHtmlVar($query, "comment_$i");
    push @pgcommands, qq(DELETE FROM cur_curdata WHERE cur_paper = '$joinkey' AND cur_paper_modifier = '$modifier' AND cur_datatype = '$datatype' AND cur_curator = '$twonum');
    push @pgcommands, qq(INSERT INTO cur_curdata VALUES ('$joinkey', '$modifier', '$datatype', '$twonum', '$posNeg', '$comment'));
  } # for my $i (1 .. $overwriteCount)
  foreach my $pgcommand (@pgcommands) {
    print "$pgcommand<br />\n";
    $dbh->do( $pgcommand );
  } # foreach my $pgcommand (@pgcommands)
} # sub overwriteSelectedResults

sub getResults {
  print qq(<form name='form1' method="post" action="svm_results.cgi">\n);

  foreach my $datatype (sort keys %datatypes) {
    ($oop, my $chosen) = &getHtmlVar($query, "checkbox_$datatype");
    print qq(<input type="hidden" name="checkbox_$datatype" value="$chosen">\n);
    if ($chosen) { $chosenDatatypes{$chosen}++; }
  } # foreach my $datatype (sort keys %datatypes)

  my @oop = $query->param("select_datesSvm");		# get the array
  unless ($oop[0]) { $oop[0] = 'all'; }			# if no datesSvm option chosen, set to "all"
  print qq(<select name="select_datesSvm" multiple="multiple" size="8" style="display:none">);
  foreach my $oop (@oop) { $oop = &untaint($oop); $chosenDatesSvm{$oop}++; print qq(<option selected="selected">$oop</option>); }
  print qq(</select>);

  ($oop, my $specificPapers) = &getHtmlVar($query, "specific_papers");
  if ($specificPapers) { my (@joinkeys) = $specificPapers =~ m/(\d+)/g; foreach (@joinkeys) { $chosenPapers{$_}++; } }
    else { $chosenPapers{'all'}++; }
  print qq(<input type="hidden" name="specific_papers" value="$specificPapers">\n);

  ($oop, my $displayCur) = &getHtmlVar($query, "checkbox_cur");
  print qq(<input type="hidden" name="checkbox_cur" value="$displayCur">\n);
  if ($displayCur) { &populateCurCurData(); }
  ($oop, my $displayOa) = &getHtmlVar($query, "checkbox_oa");
  print qq(<input type="hidden" name="checkbox_oa" value="$displayOa">\n);
  if ($displayOa) { &populateOa(); }
  ($oop, my $displayCfp) = &getHtmlVar($query, "checkbox_cfp");
  print qq(<input type="hidden" name="checkbox_cfp" value="$displayCfp">\n);
  if ($displayCfp) { &populateCfp(); }
  ($oop, my $displayAfp) = &getHtmlVar($query, "checkbox_afp");
  print qq(<input type="hidden" name="checkbox_afp" value="$displayAfp">\n);
  if ($displayAfp) { &populateAfp(); }
  ($oop, my $displayRandom) = &getHtmlVar($query, "checkbox_random");
  print qq(<input type="hidden" name="checkbox_random" value="$displayRandom">\n);

  ($oop, my $showJournal) = &getHtmlVar($query, "checkbox_journal");
  print qq(<input type="hidden" name="checkbox_journal" value="$showJournal">\n);
  ($oop, my $showPmid) = &getHtmlVar($query, "checkbox_pmid");
  print qq(<input type="hidden" name="checkbox_pmid" value="$showPmid">\n);
  ($oop, my $showPdf) = &getHtmlVar($query, "checkbox_pdf");
  print qq(<input type="hidden" name="checkbox_pdf" value="$showPdf">\n);
  ($oop, my $showPrimary) = &getHtmlVar($query, "checkbox_primary");
  print qq(<input type="hidden" name="checkbox_primary" value="$showPrimary">\n);

  ($oop, my $papersPerPage) = &getHtmlVar($query, "papers_per_page");
  print qq(<input type="hidden" name="papers_per_page" value="$papersPerPage">\n);
  ($oop, my $pageSelected) = &getHtmlVar($query, "select_page");

  ($oop, my $doneYes) = &getHtmlVar($query, "checkbox_doneyes");
  print qq(<input type="hidden" name="checkbox_doneyes" value="$doneYes">\n);
  ($oop, my $doneNo) = &getHtmlVar($query, "checkbox_doneno");
  print qq(<input type="hidden" name="checkbox_doneno"  value="$doneNo">\n);

  ($oop, my $svmPos) = &getHtmlVar($query, "checkbox_svmpos");
  print qq(<input type="hidden" name="checkbox_svmpos" value="$svmPos">\n);
  ($oop, my $svmNeg) = &getHtmlVar($query, "checkbox_svmneg");
  print qq(<input type="hidden" name="checkbox_svmneg" value="$svmNeg">\n);

  ($oop, my $truePos) = &getHtmlVar($query, "checkbox_truepos");
  print qq(<input type="hidden" name="checkbox_truepos" value="$truePos">\n);
  ($oop, my $trueNeg) = &getHtmlVar($query, "checkbox_trueneg");
  print qq(<input type="hidden" name="checkbox_trueneg" value="$trueNeg">\n);
  ($oop, my $falsePos) = &getHtmlVar($query, "checkbox_falsepos");
  print qq(<input type="hidden" name="checkbox_falsepos" value="$falsePos">\n);
  ($oop, my $falseNeg) = &getHtmlVar($query, "checkbox_falseneg");
  print qq(<input type="hidden" name="checkbox_falseneg" value="$falseNeg">\n);

  &populateCurSvmData();

  my @headerRow = qw( paperID );
  if ($showJournal) { push @headerRow, "journal"; &populateJournal(); }
  if ($showPmid)    { push @headerRow, "pmid";    &populatePmid();    }
  if ($showPdf)     { push @headerRow, "pdf";     &populatePdf();     }
  if ($showPrimary) { push @headerRow, "primary"; &populatePrimary(); }
  push @headerRow, "mod";

  my %trs;				# td data for each table row
  my %paperPosNegOkay;			# papers that have positive-negative data okay, so show all svm results for that paper even if a given row isn't positive-negative okay
  my %paperInfo;			# for a joinkey, all the paper information about it to show in a big rowspan for that table row 

  foreach my $joinkey (sort keys %svmData) {
    if ($svmPos && !$svmNeg) { next unless ($svmPos{$joinkey}); }	# show only positive, skip unless paper is positive
    if (!$svmPos && $svmNeg) { next unless ($svmNeg{$joinkey}); }	# show only negative, skip unless paper is negative

    if ($doneYes && !$doneNo) {						# show only curated data E<br>\n";
      next unless ( $curData{$joinkey} || $oaData{$joinkey} || $cfp{$joinkey} || $afp{$joinkey} ) }		# skip unless any tables has this data
    if (!$doneYes && $doneNo) {						# show only uncurated data
      next if ( $curData{$joinkey} || $oaData{$joinkey} || $cfp{$joinkey} || $afp{$joinkey} ) }			# skip if any tables has this data
      
#     my @paperInfoArray = ( "$joinkey", "$modifier" );
    push @{ $paperInfo{$joinkey} }, $joinkey;
    my $journal = ''; my $pmid = ''; my $pdf = ''; my $primaryData = '';
    if ($showJournal) { 
      if ($journal{$joinkey}) { $journal = $journal{$joinkey}; }
#       push @paperInfoArray, $journal;
      push @{ $paperInfo{$joinkey} }, $journal; }
    if ($showPmid) { 
      if ($pmid{$joinkey}) { $pmid = $pmid{$joinkey}; }
#       push @paperInfoArray, $pmid;
      push @{ $paperInfo{$joinkey} }, $pmid; }
    if ($showPdf) { 
      if ($pdf{$joinkey}) { $pdf = $pdf{$joinkey}; }
#       push @paperInfoArray, $pdf;
      push @{ $paperInfo{$joinkey} }, $pdf; }
    if ($showPrimary) { 
      if ($primaryData{$joinkey}) { $primaryData = $primaryData{$joinkey}; }
#       push @paperInfoArray, $primaryData;
      push @{ $paperInfo{$joinkey} }, $primaryData; }
    foreach my $modifier (sort keys %{ $svmData{$joinkey} }) {

      foreach my $datatype (sort keys %{ $svmData{$joinkey}{$modifier} }) {
        next unless ($chosenDatatypes{$datatype});			# show only results for selected datatype
        foreach my $date (sort keys %{ $svmData{$joinkey}{$modifier}{$datatype} }) {
          my $svmResult = $svmData{$joinkey}{$modifier}{$datatype}{$date}; 
          my $bgcolor = 'white'; my $svmFlag = 0;
          if ($svmResult eq 'high')      { $bgcolor = '#FFA0A0'; $svmFlag++; }
          elsif ($svmResult eq 'medium') { $bgcolor = '#FFC8C8'; $svmFlag++; }
          elsif ($svmResult eq 'low')    { $bgcolor = '#FFE0E0'; $svmFlag++; }
          $svmResult = qq(<span style="background-color: $bgcolor">$svmResult</span>);
          my @dataRow = ( "$modifier", "$datatype", "$date", "$svmResult" ); 
#           foreach (@paperInfoArray) { push @dataRow, $_; }
#           push @dataRow, $datatype;  push @dataRow, $date; push @dataRow, $svmResult;

          my ($isTP, $isFN, $isFP, $isTN) = (0, 0, 0, 0);
          if ($displayCur) {
            my @twonums; my @curResults; my @comments; my @trueFalses;
            foreach my $twonum (sort keys %{ $curData{$joinkey}{$modifier}{$datatype} }) {
              my $trueFalse = 'TN';
              my $curResult = $curData{$joinkey}{$modifier}{$datatype}{$twonum}{posneg}; my $curFlag = 0;
              if ($curData{$joinkey}{$modifier}{$datatype}{$twonum}{posneg} eq 'positive') { $curFlag = 1; }
                elsif ($curData{$joinkey}{$modifier}{$datatype}{$twonum}{posneg} eq 'negative') { $curFlag = 0; }
              my $comment = $curData{$joinkey}{$modifier}{$datatype}{$twonum}{comment};
              my $commentText = $premadeComments{$comment};
              if ($svmFlag && $curFlag) { $trueFalse = qq(<span style="background-color: #47C247">TP</span>); $isTP++; }
                elsif (!$svmFlag && $curFlag) { $trueFalse = qq(<span style="background-color: #99FF99">FN</span>); $isFN++; }
                elsif ($svmFlag && !$curFlag) { $trueFalse = qq(<span style="background-color: yellow">FP</span>); $isFP++; }
                elsif (!$svmFlag && !$curFlag) { $trueFalse = 'TN'; $isTN++; }
                else { $trueFalse = 'logic error in CFP trueFalse' }
              push @twonums, $curators{$twonum};
              push @curResults, $curResult;
              push @comments, $commentText;
              push @trueFalses, $trueFalse;
            } # foreach my $twonum (sort keys %{ $curData{$joinkey}{$modifier}{$datatype} })
            my $twonum = join"<br>", @twonums; my $curResult = join"<br>", @curResults; my $comment = join"<br>", @comments; my $trueFalse = join"<br>", @trueFalses;
            push @dataRow, $twonum; push @dataRow, $curResult; push @dataRow, $comment; push @dataRow, $trueFalse; 
          } # if ($displayCur)

          if ($displayOa) {
            my $oaResult = 'oa blank'; my $oaFlag = 0; my $trueFalse = 'TN';
            if ($oaData{$joinkey}{$datatype}) { $oaResult = $oaData{$joinkey}{$datatype}; $oaFlag++; }
            if ($svmFlag && $oaFlag) { $trueFalse = qq(<span style="background-color: #47C247">TP</span>); $isTP++; }
              elsif (!$svmFlag && $oaFlag) { $trueFalse = qq(<span style="background-color: #99FF99">FN</span>); $isFN++; }
              elsif ($svmFlag && !$oaFlag) { $trueFalse = qq(<span style="background-color: yellow">n/a</span>); }
              elsif (!$svmFlag && !$oaFlag) { $trueFalse = 'n/a'; }
#               elsif ($svmFlag && !$oaFlag) { $trueFalse = qq(<span style="background-color: yellow">?FP</span>); $isFP++; }
#               elsif (!$svmFlag && !$oaFlag) { $trueFalse = '?TN'; $isTN++; }
              else { $trueFalse = 'logic error in CFP trueFalse' }
            push @dataRow, $oaResult; 
            push @dataRow, $trueFalse; 
          }

          if ($displayCfp) {
#             my $cfpResult = 'cfp blank'; my $cfpFlag = 0; my $trueFalse = 'TN';
            my $cfpResult = ''; my $cfpFlag = 0; my $trueFalse = 'TN';
            if ($cfp{$joinkey}{$datatype}) { $cfpResult = $cfp{$joinkey}{$datatype}; $cfpFlag++; }
            if ($svmFlag && $cfpFlag) { $trueFalse = qq(<span style="background-color: #47C247">TP</span>); $isTP++; }
              elsif (!$svmFlag && $cfpFlag) { $trueFalse = qq(<span style="background-color: #99FF99">FN</span>); $isFN++; }
              elsif ($svmFlag && !$cfpFlag) { $trueFalse = qq(<span style="background-color: yellow">n/a</span>); }
              elsif (!$svmFlag && !$cfpFlag) { $trueFalse = 'n/a'; }
#               elsif ($svmFlag && !$cfpFlag) { $trueFalse = qq(<span style="background-color: yellow">?FP</span>); $isFP++; }
#               elsif (!$svmFlag && !$cfpFlag) { $trueFalse = '?TN'; $isTN++; }
              else { $trueFalse = 'logic error in CFP trueFalse' }
            push @dataRow, $cfpResult; 
            push @dataRow, $trueFalse; 
          }

          if ($displayAfp) {
#             my $afpResult = 'afp blank'; my $afpFlag = 0; my $trueFalse = 'TN';
            my $afpResult = ''; my $afpFlag = 0; my $trueFalse = 'TN';
            if ($afp{$joinkey}{$datatype}) { $afpResult = $afp{$joinkey}{$datatype}; $afpFlag++; }
            if ($svmFlag && $afpFlag) { $trueFalse = qq(<span style="background-color: #47C247">TP</span>); $isTP++; }
              elsif (!$svmFlag && $afpFlag) { $trueFalse = qq(<span style="background-color: #99FF99">FN</span>); $isFN++; }
              elsif ($svmFlag && !$afpFlag) { $trueFalse = qq(<span style="background-color: yellow">n/a</span>); }
              elsif (!$svmFlag && !$afpFlag) { $trueFalse = 'n/a'; }
#               elsif ($svmFlag && !$afpFlag) { $trueFalse = qq(<span style="background-color: yellow">?FP</span>); $isFP++; }
#               elsif (!$svmFlag && !$afpFlag) { $trueFalse = '?TN'; $isTN++; }
              else { $trueFalse = 'logic error in CFP trueFalse' }
            push @dataRow, $afpResult; 
            push @dataRow, $trueFalse; 
          }

          if ($displayRandom) {
            my $randomFlag = int(rand(2)); my $trueFalse = 'TN';
            if ($svmFlag && $randomFlag) { $trueFalse = qq(<span style="background-color: #47C247">TP</span>); $isTP++; }
              elsif (!$svmFlag && $randomFlag) { $trueFalse = qq(<span style="background-color: #99FF99">FN</span>); $isFN++; }
              elsif ($svmFlag && !$randomFlag) { $trueFalse = qq(<span style="background-color: yellow">FP</span>); $isFP++; }
              elsif (!$svmFlag && !$randomFlag) { $trueFalse = 'TN'; $isTN++; }
              else { $trueFalse = 'logic error in CFP trueFalse' }
            push @dataRow, $randomFlag; 
            push @dataRow, $trueFalse; 
          }

          if ( $truePos  || $trueNeg  || $falsePos || $falseNeg ) {	# if any  true/false pos/neg conditions  need to be checked
              my $PN_okay = 0;						# if any true/false pos/neg conditions match
              if ( $truePos  && $isTP ) { $PN_okay++; }
              if ( $trueNeg  && $isTN ) { $PN_okay++; }
              if ( $falsePos && $isFP ) { $PN_okay++; }
              if ( $falseNeg && $isFN ) { $PN_okay++; }
              if ($PN_okay) { $paperPosNegOkay{$joinkey}++; } }		# if true/false pos/neg conditions it's a positive paper
            else { $paperPosNegOkay{$joinkey}++; } 			# if no true/false pos/neg conditions to check it's a positive paper

          my $trData = join"</td>$tdDot", @dataRow;
#           push @{ $trs{$joinkey} }, qq(<tr>${tdDot}$trData</td></tr>\n);
          push @{ $trs{$joinkey} }, qq(${tdDot}$trData</td></tr>\n);
        } # foreach my $date (sort keys %{ $svmData{$joinkey}{$modifier}{$datatype} })
      } # foreach my $datatype (sort keys %{ $svmData{$joinkey}{$modifier} })
    } # foreach my $modifier (sort keys %{ $svmData{$joinkey} })
  } # foreach my $joinkey (sort keys %svmData)

  my $joinkeysAmount = scalar(keys %paperPosNegOkay);
  my $pagesAmount = ceil($joinkeysAmount / $papersPerPage);
  print qq(Page number <select name="select_page">);
  for my $i (1 .. $pagesAmount) { 
    if ($i == $pageSelected) { print qq(<option selected="selected">$i</option>\n); }
      else { print qq(<option>$i</option>\n); }
  } # for my $i (1 .. $pagesAmount)
  print qq(</select>);
  print qq(<input type="submit" name="action" value="Get Results">\n);
#   print "pagesAmount $pagesAmount<br/>\n";
  print qq(amount of papers $joinkeysAmount<br/>\n);
  print qq(<br />\n);

  print qq(<table border="1">\n);
  push @headerRow, "datatype";  push @headerRow, "date"; push @headerRow, "SVM Prediction";
  if ($displayCur)    { push @headerRow, "curator"; push @headerRow, "cur value"; push @headerRow, "cur comment"; push @headerRow, "cur PN"; }
  if ($displayOa)     { push @headerRow, "oa value"; push @headerRow, "oa PN"; }
  if ($displayCfp)    { push @headerRow, "cfp value";  push @headerRow, "cfp PN"; }
  if ($displayAfp)    { push @headerRow, "afp value";  push @headerRow, "afp PN"; }
  if ($displayRandom) { push @headerRow, "random value";  push @headerRow, "random PN"; }
  my $headerRow = join"</th>$thDot", @headerRow;
  $headerRow = qq(<tr>$thDot) . $headerRow . qq(</th></tr>);
  print qq($headerRow\n);

  my $papCount = 0;
  my $papCountToSkip = 0; my $papToSkip = ($pageSelected - 1 ) * $papersPerPage;
  foreach my $joinkey (sort keys %paperPosNegOkay) {			# from all papers that have good positve-negative values, show all TRs
    $papCountToSkip++; next if ($papCountToSkip <= $papToSkip);		# skip entries until at the proper page
    $papCount++; 
    last if ($papCount > $papersPerPage);
    my $trsInPaperAmount = scalar @{ $trs{$joinkey} };			# amount of rows for a joinkey, make that the rowspan
    my $firstTr = shift @{ $trs{$joinkey} };				# the first table row needs the paper info and rowspan
    my $tdMultiRow = $tdDot; $tdMultiRow =~ s/>$/ rowspan="$trsInPaperAmount">/;	# add the rowspan to the td style
    my $paperInfoTds = join"</td>$tdMultiRow", @{ $paperInfo{$joinkey} };		# make paper info tds from %paperInfo
    print qq(<tr>${tdMultiRow}$paperInfoTds</td>$firstTr\n); 		# print the first row which has paper info
    foreach my $tr (@{ $trs{$joinkey} }) { print qq(<tr>$tr\n); } }	# print other table rows without paper info
  print qq(</table>\n);
    
  print qq(</form>\n);
} # sub getResults


sub populateAfp {
  foreach my $datatype (sort keys %datatypes) { 
    if ($datatype eq 'geneprod_GO') { $datatype = 'geneprod'; }
    $result = $dbh->prepare( "SELECT * FROM afp_$datatype" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $afp{$row[0]}{$datatype} = $row[1]; }
  } # foreach my $datatype (sort keys %datatypes) 
} # sub populateCfp

sub populateCfp {
  foreach my $datatype (sort keys %datatypes) { 
    if ($datatype eq 'geneprod_GO') { $datatype = 'geneprod'; }
    $result = $dbh->prepare( "SELECT * FROM cfp_$datatype" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) { $cfp{$row[0]}{$datatype} = $row[1]; }
  } # foreach my $datatype (sort keys %datatypes) 
} # sub populateCfp

sub populateOa {
  if ($chosenDatatypes{'newmutant'}) {
    $result = $dbh->prepare( "SELECT * FROM app_paper" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{$paper}{'newmutant'} = 'positive'; } } }
  if ($chosenDatatypes{'overexpr'}) {
    $result = $dbh->prepare( "SELECT * FROM app_paper WHERE joinkey IN (SELECT joinkey FROM app_transgene WHERE app_transgene IS NOT NULL AND app_transgene != '')" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{$paper}{'overexpr'} = 'positive'; } } }

  if ($chosenDatatypes{'otherexpr'}) {
    $result = $dbh->prepare( "SELECT * FROM exp_paper" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{$paper}{'otherexpr'} = 'positive'; } } }

  if ($chosenDatatypes{'genereg'}) {
    $result = $dbh->prepare( "SELECT * FROM grg_paper" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{$paper}{'genereg'} = 'positive'; } } }

  if ($chosenDatatypes{'geneint'}) {
    $result = $dbh->prepare( "SELECT * FROM int_paper" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{$paper}{'geneint'} = 'positive'; } } }

  if ($chosenDatatypes{'rnai'}) {
    $result = $dbh->prepare( "SELECT * FROM rna_paper" );
    $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
    while (my @row = $result->fetchrow) {
      my (@papers) = $row[1] =~ m/WBPaper(\d+)/g;
      foreach my $paper (@papers) {
        $oaData{$paper}{'rnai'} = 'positive'; } } }
} # sub populateCfp

sub populateCurCurData {
  $result = $dbh->prepare( "SELECT * FROM cur_curdata" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    $curData{$row[0]}{$row[1]}{$row[2]}{$row[3]}{posneg}    = $row[4]; 
    $curData{$row[0]}{$row[1]}{$row[2]}{$row[3]}{comment}   = $row[5];
    $curData{$row[0]}{$row[1]}{$row[2]}{$row[3]}{timestamp} = $row[6]; }
} # sub populateCurCurData

sub populateCurSvmData {
  $result = $dbh->prepare( "SELECT * FROM cur_svmdata ORDER BY cur_paper, cur_paper_modifier, cur_datatype, cur_date" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) {
    my ($joinkey, $modifier, $datatype, $date, $result, $version, $timestamp) = @row;
    next unless ($chosenPapers{$joinkey} || $chosenPapers{all});
    next unless ($chosenDatesSvm{$date}  || $chosenDatesSvm{all});
    next unless ($chosenDatatypes{$datatype});

#     my ($short_version) = $version =~ m/(v\d+)/;
    $svmData{$joinkey}{$modifier}{$datatype}{$date} = $result;
    if ($result eq 'NEG') { $svmNeg{$joinkey}++; }
      else { $svmPos{$joinkey}++; }
# COMMENT OUT FOR SMALLER SET
#     if (scalar keys %svmData > 30) { delete $svmData{$joinkey}; last; }
  }
} # sub populateCurSvmData


sub populatePrimary {
  $result = $dbh->prepare( "SELECT * FROM pap_primary_data WHERE pap_primary_data IS NOT NULL" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $primaryData{$row[0]} = $row[1]; } }
} # sub populatePrimary

sub populateJournal {
  $result = $dbh->prepare( "SELECT * FROM pap_journal WHERE pap_journal IS NOT NULL" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { if ($row[0]) { $journal{$row[0]} = $row[1]; } }
} # sub populateJournal

sub populatePmid {
  $result = $dbh->prepare( "SELECT * FROM pap_identifier WHERE pap_identifier ~ 'pmid'" );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my %temp;
  while (my @row = $result->fetchrow) { if ($row[0]) { 
    my ($data) = &makeNcbiLinkFromPmid($row[1]);
    $temp{$row[0]}{$data}++; } }
  foreach my $joinkey (sort keys %temp) {
    my ($pmids) = join"<br/>", keys %{ $temp{$joinkey} };
    $pmid{$joinkey} = $pmids;
  } # foreach my $joinkey (sort keys %temp)
} # sub populatePmid

sub populatePdf {
  $result = $dbh->prepare( "SELECT * FROM pap_electronic_path WHERE pap_electronic_path IS NOT NULL");
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  my %temp;
  while (my @row = $result->fetchrow) {
    my ($data, $isPdf) = &makePdfLinkFromPath($row[1]);
    $temp{$row[0]}{$isPdf}{$data}++; }
  foreach my $joinkey (sort keys %temp) {
    my @pdfs;
    foreach my $isPdf (reverse sort keys %{ $temp{$joinkey} }) { 
      foreach my $pdfLink (sort keys %{ $temp{$joinkey}{$isPdf} }) { 
        push @pdfs, $pdfLink; } }
    my ($pdfs) = join"<br/>", @pdfs;
    $pdf{$joinkey} = $pdfs;
  }
} # sub populatePdf

sub makePdfLinkFromPath {
  my ($path) = shift;
  my ($pdf) = $path =~ m/\/([^\/]*)$/;
  my $isPdf = 0; if ($pdf =~ m/\.pdf$/) { $isPdf++; }		# kimberly wants .pdf files on top, so need to flag to sort
  my $link = 'http://tazendra.caltech.edu/~acedb/daniel/' . $pdf;
  my $data = "<a href=\"$link\" target=\"new\">$pdf</a>"; return ($data, $isPdf); }
sub makeNcbiLinkFromPmid {
  my $pmid = shift;
  my ($id) = $pmid =~ m/(\d+)/;
  my $link = 'http://www.ncbi.nlm.nih.gov/pubmed/' . $id;
  my $data = "<a href=\"$link\" target=\"new\">$pmid</a>"; return $data; }


sub populateDatatypes {
  $result = $dbh->prepare( "SELECT DISTINCT(cur_datatype) FROM cur_svmdata " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $datatypes{$row[0]}++; }
} # sub populateDatatypes
sub populateDatesSvm {
  $result = $dbh->prepare( "SELECT DISTINCT(cur_date) FROM cur_svmdata " );
  $result->execute() or die "Cannot prepare statement: $DBI::errstr\n"; 
  while (my @row = $result->fetchrow) { $datesSvm{$row[0]}++; }
} # sub populateDatesSvm

sub populatePosNegOptions {
  $posNegOptions{"positive"} = "Curator Positive (True Positive OR False Negative)";
  $posNegOptions{"negative"} = "Curator Negative (True Negative OR False Positive)";
}
sub populateCurators {
  $curators{"two1823"}  = "Juancarlos Chan";
  $curators{"two12028"} = "Daniela Raciti";
  $curators{"two1843"}  = "Kimberly Van Auken";
} # sub populateCurators
sub populatePremadeComments {
  $premadeComments{"1"} = "SVM Positive, Curation Negative";
  $premadeComments{"2"} = "pre-made comment #2";
  $premadeComments{"3"} = "pre-made comment #3";
} # sub populatePremadeComments

__END__


#   if ($action eq 'AllPapersHtml') { &allPapers('html'); }
#   elsif ($action eq 'AllPapersTxt') { &allPapers('txt'); }
#   my $allPapersHtmlLink = 'svm_results.cgi?action=AllPapersHtml';
#   print qq(<a href="$allPapersHtmlLink">All Papers in HTML table</a><br/>\n);
#   my $allPapersTxtLink = 'svm_results.cgi?action=AllPapersTxt';
#   print qq(<a href="$allPapersTxtLink">All Papers in Text format</a><br/>\n);
# sub allPapers {		# nobody wants this, Yuling will get stuff from postgres directly
#   my ($outputStyle) = @_;
#   if ($outputStyle eq 'txt') { print "Content-type: txt/plain\n\n"; }
#     else { &printHeader('SVM summary'); }
#   &populateJournal();
# #   print "Display of data from date directories from postgres table svm_result<br />\n";
#   &populateCfp(); 
#   &populateByPaper();
# 
#   if ($outputStyle eq 'html') { print "<table border=\"1\">\n"; }
#   my @headerRow = qw( paperID mod journal );
#   foreach my $datatype (sort keys %datatypes) { push @headerRow, $datatype; }
#   my $headerRow = '';
#   if ($outputStyle eq 'txt') { $headerRow = join"\t", @headerRow; }
#     else {
#       $headerRow = join'</th><th style="border-style: dotted">', @headerRow;
#       $headerRow = qq(<tr><th style="border-style: dotted">) . $headerRow . qq(</th></tr>); }
#   print "$headerRow\n";
# #   print qq(<tr><th style="border-style: dotted">paperID</th><th style="border-style: dotted">mod</th><th style="border-style: dotted">journal</th>);
# #   foreach my $datatype (sort keys %datatypes) { print qq(<th style="border-style: dotted">$datatype</th>); }
# #   print "</tr>\n";
#   foreach my $joinkey (sort keys %byPaper) {
#     my $journal = '';
#     if ($journal{$joinkey}) { $journal = $journal{$joinkey}; }
#     foreach my $modifier (sort keys %{ $byPaper{$joinkey} }) {
#       my @dataRow = ( $joinkey, $modifier, $journal );
# #       print qq(<tr>${tdDot}$joinkey</td>${tdDot}$modifier</td>${tdDot}$journal</td>);
#       foreach my $datatype (sort keys %datatypes) {
# #       foreach my $datatype (sort keys %{ $byPaper{$joinkey}{$modifier} }) {
# #         print qq(${tdDot});
#         my @datatypeCell = ();
#         my $cfp = 'cfp blank '; my $bgcolor = 'white'; if ($cfp{$datatype}{$joinkey}) { $cfp = "cfp yes"; $bgcolor = 'cyan'; } 
#         if ($outputStyle eq 'txt') { push @datatypeCell, $cfp; }
#           else { push @datatypeCell, qq(<span style="background-color: $bgcolor">$cfp</span><br/>); }
#         foreach my $version (sort keys %{ $byPaper{$joinkey}{$modifier}{$datatype} }) {
#           my $result = $byPaper{$joinkey}{$modifier}{$datatype}{$version};
#           my $bgcolor = 'white';
#           if ($result eq 'high')      { $bgcolor = '#FFa0a0'; }
#           elsif ($result eq 'medium') { $bgcolor = '#FFc8c8'; }
#           elsif ($result eq 'low')    { $bgcolor = '#FFe0e0'; }
#           if ($outputStyle eq 'txt') { push @datatypeCell, "$version $result"; }
#             else { push @datatypeCell, qq(<span style="background-color: $bgcolor">$datatype $version $result</span><br/>); }
#         } # foreach my $version (sort keys %{ $byPaper{$joinkey}{$modifier}{$datatype} })
#         my $datatypeCell = join" | ", @datatypeCell;
#         push @dataRow, $datatypeCell;
# #         print "</td>";
# #       } # foreach my $datatype (sort keys %{ $byPaper{$joinkey}{$modifier} })
#       } # foreach my $datatype (sort keys %datatypes)
# #       print "</td></tr>\n";
#       my $dataRow;
#       if ($outputStyle eq 'txt') { $dataRow = join"\t", @dataRow; }
#         else {
#           $dataRow = join'</td>${tdDot}', @dataRow;
#           $dataRow = qq(<tr>${tdDot}) . $dataRow . qq(</td></tr>); }
#       print "$dataRow\n";
#     } # foreach my $modifier (sort keys %{ $byPaper{$joinkey} })
#   } # foreach my $joinkey (sort keys %byPaper)
#   if ($outputStyle eq 'html') { print "</table>\n"; }
# 
# #   print "<table border=\"1\">\n";
# #   print "<tr><td style=\"border-style: dotted\">paper</td><td style=\"border-style: dotted\">journal</td><td style=\"border-style: dotted\">data</td></tr>\n";
# #   foreach my $paper (sort keys %byPaper) {
# #     print "<tr><td style=\"border-style: dotted\">$paper</td>";
# #     my ($joinkey) = $paper =~ m/(\d+)/;
# #     if ($journal{$joinkey}) { print "<td style=\"border-style: dotted\" class=\"$journal{$joinkey}\">$journal{$joinkey}</td>"; } else { print "<td>&nbsp;</td>"; }
# #     foreach my $type (sort keys %{ $byPaper{$paper} }) {
# #       next unless ($type);
# #       my $bgcolor = 'white';
# #       my $result = $byPaper{$paper}{$type};
# #       if ($result eq 'high')   { $bgcolor = '#FFa0a0'; }
# #       if ($result eq 'medium') { $bgcolor = '#FFc8c8'; }
# #       if ($result eq 'low')    { $bgcolor = '#FFe0e0'; }
# #       print "<td style=\"border-style: dotted; background-color: $bgcolor\">$type - $result</td>";
# #     } # foreach my $type (sort keys %{ $byPaper{$paper} })
# #     print "</tr>\n";
# #   } # foreach my paper (sort keys %byPaper)
# #   print "</table>\n";
#   if ($outputStyle eq 'html') { &printFooter(); }
# } # sub allPapers

sub junk {
#   my $root_url = 'http://caprica.caltech.edu/celegans/svm_results/';
  my $root_url = 'http://131.215.52.209/celegans/svm_results/';
  print "Display of data from date directories from $root_url<br />\n";

  my $count = 0;
  my $root_page = get $root_url;
#   print "R $root_page\n";
  my (@dates) = $root_page =~ m/<a href=\"(\d+\/)\">/g;
  foreach my $date (@dates) {
#     $count++; last if ($count > 4);
    my $date_url = $root_url . $date;
#     print "<a href=$date_url>$date_url</a><br />\n";
    my $date_page = get $date_url;
# print "$date_page\n";
    my (@date_types) = $date_page =~ m/<a href=\"(\w+)\"/g;
    foreach my $date_type (@date_types) {
      my ($type) = $date_type =~ m/^[\d_]+_(\w+)$/;
#       print $type;
      my $date_type_url = $date_url . $date_type;
#       print "<a href=$date_type_url>$date_type_url</a><br />\n";
      my $date_type_results_page = get $date_type_url;
      my (@results) = split/\n/, $date_type_results_page;
      foreach my $result (@results) { 
        if ($result =~ m/\"/) { $result =~ s/\"//g; }
        my ($paper, $flag) = split/\t/, $result;
        next unless ($paper =~ m/^WBPaper/);
        $byPaper{$paper}{$type} = $flag;
        $hash{$type}{$paper} = $flag;
        $hash{all}{$paper}++;
      }
    } # foreach my $type (@types)
    my $fn_date_url = $date_url . 'checkFalseNegatives/';
    my $fn_date_page = get $fn_date_url;
    my (@fn_date_types) = $fn_date_page =~ m/<a href=\"(\w+)\"/g;
    foreach my $fn_date_type (@fn_date_types) {
      my ($type) = $fn_date_type =~ m/^[\d_]+_checkFN_(\w+)$/;
#       print $type;
      my $fn_date_type_url = $fn_date_url . $fn_date_type;
#       print "<a href=$fn_date_type_url>$fn_date_type_url</a><br />\n";
      my $fn_date_type_results_page = get $fn_date_type_url;
      my (@results) = split/\n/, $fn_date_type_results_page;
      foreach my $paper (@results) { 
        next unless ($paper =~ m/^WBPaper/);
        my $flag = 'NEG';
        $byPaper{$paper}{$type} = 'NEG';
        $hash{$type}{$paper} = $flag;
        $hash{all}{$paper}++;
      }
    } # foreach my $type (@types)
  } # foreach my $subdir (@subdirs)

print "journal filter : <input id=\"journal_filter\" onKeyUp=\"filterData('journal_filter')\">\n";
# print "paper filter : <input id=\"paper_filter\" onKeyUp=\"filterData('paper_filter')\"><br /><br />\n";
print "<div id=\"bug\"></div>\n";
  print << "EndOfText";
<script type="text/javascript" language="JavaScript">
function filterData(column) {
  var message = '';
// message += column;
  var columnFilter = document.getElementById(column).value;
//   var journalFilter = document.getElementById('journal_filter').value;
  var regexColumn = new RegExp(columnFilter, "i")
  var arrTd = document.getElementsByTagName("td");
  for (var i = 0; i < arrTd.length; i++) {
    if (arrTd[i].className) {
      var className = arrTd[i].className;
// message += "match className " + className + " ";
      if (className.match(regexColumn)) { arrTd[i].parentNode.style.display = ""; }
        else { arrTd[i].parentNode.style.display = "none"; }
    }
  }
  document.getElementById("bug").innerHTML = message;
//   alert(journal_filter);
}
</script>
EndOfText

  print "<table border=\"1\">\n";
  print "<tr><td style=\"border-style: dotted\">paper</td><td style=\"border-style: dotted\">journal</td><td style=\"border-style: dotted\">data</td></tr>\n";
  foreach my $paper (sort keys %byPaper) {
    print "<tr><td style=\"border-style: dotted\">$paper</td>";
    my ($joinkey) = $paper =~ m/(\d+)/;
    if ($journal{$joinkey}) { print "<td style=\"border-style: dotted\" class=\"$journal{$joinkey}\">$journal{$joinkey}</td>"; } else { print "<td>&nbsp;</td>"; }
    foreach my $type (sort keys %{ $byPaper{$paper} }) {
      next unless ($type);
      my $bgcolor = 'white';
      my $result = $byPaper{$paper}{$type};
      if ($result eq 'high')   { $bgcolor = '#FFa0a0'; }
      if ($result eq 'medium') { $bgcolor = '#FFc8c8'; }
      if ($result eq 'low')    { $bgcolor = '#FFe0e0'; }
      print "<td style=\"border-style: dotted; background-color: $bgcolor\">$type - $result</td>";
    } # foreach my $type (sort keys %{ $byPaper{$paper} })
    print "</tr>\n";
  } # foreach my paper (sort keys %byPaper)
  print "</table>\n";

#   foreach my $type (sort keys %hash) {
#     next unless ($type);
#     next if ($type eq 'all');
# #     print "<a href=\"#$type\">$type<\a> ";
#   }
#   print "<br /><br />\n";

#   print "<table>\n";
#   foreach my $paper (sort keys %{ $hash{all} }) {
# #     print "$paper has been flagged for svm $hash{all}{$paper} times<br />\n";
#     print "<tr><td>$paper</td><td>$hash{all}{$paper}</td></tr>\n";
#   } # foreach my $paper (sort keys %{ $hash{all} })
#   print "</table>\n";

#   print "<br /><br />\n";
#   foreach my $type (sort keys %hash) {
#     next unless ($type);
#     next if ($type eq 'all');
#     print "<a name=\"$type\">Type : $type</a><br />\n";
#     foreach my $paper (sort keys %{ $hash{$type} }) {
#       print "$paper\t$hash{$type}{$paper}<br />\n";
#     }
#     print "<br /><br />\n";
#   } # foreach my $type (sort keys %hash)
}

__END__

#!/usr/bin/perl -w

# sample PG query

use strict;
use diagnostics;
use DBI;
use Encode qw( from_to is_utf8 );

my $dbh = DBI->connect ( "dbi:Pg:dbname=testdb", "", "") or die "Cannot connect to database!\n"; 

