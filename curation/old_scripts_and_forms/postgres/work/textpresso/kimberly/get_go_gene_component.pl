#!/usr/bin/perl

# /usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans3/Data/indices/body/semantic/categories
# 
# look for gene_celegans && localization_cell_components && localization_verbs && localization_other
# 
# papers and senteces with each category at :
# /usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans3/Data/indices/body/semantic/categories/
# 
# Sentences at 	: /usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans3/Data/processedfiles/body/WBPaper00001003
# Grammar at 	: /usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans3/Data/annotations/body/semantic/WBPaper00001003
# 
# 
# output :
# just_sentences_20070315.1507 :
#   score, paperID, sentenceID
#   sentence with markup
#   DIVIDER
# full_sentence_data_20070315.1507 :
#   score, paperID, sentenceID
#   sentence with markup
#   sentence with full textpresso markup
#   DIVIDER
# good_senteces_file.20070315.1521 :  (use this for form)
#   number<TAB>score, paperID, sentenceID<TAB>genes<TAB>components<TAB>sentence with markup
#
# 2007 03 15
#
# Changed to protein_celegans instead of gene_celegans  2007 07 31
#
# Sort by paper instead of score for Kimberly  2007 08 07
#
# Change date of files to 090507
#
# Sort by paper -> sentence number -> score  for Kimberly  2008 03 07


use strict;
# my @files = qw( gene_celegans localization_cell_components_012607 localization_verbs_012607 localization_other_012607 );
# my @files = qw( protein_celegans localization_cell_components_012607 localization_verbs_012607 localization_other_012607 );
my @files = qw( protein_celegans localization_cell_components_090507 localization_verbs_090507 localization_other_090507 );
my $directory = '/usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans3/Data/indices/body/semantic/categories';

my $stime = time;

my %hash;
foreach my $file (@files) {
  my $open_file = "$directory/$file";
  open (IN, "<$open_file") or die "Cannot open $open_file : $!"; 
  while (my $line = <IN>) {
    chomp $line;
    my (@sent) = split/,/, $line;
    my $key = shift @sent;
    foreach my $sent (@sent) { 
      ($sent) = $sent =~ m/(\d+)/;		# sort by sentences numerically, so need this to be a number  2008 03 07
      $hash{$key}{$sent}{$file}++; }
  } # while (my $line = <IN>)
  close (IN) or die "Cannot close $open_file : $!"; 
} # foreach my $file (@files)

my %good;
foreach my $pap (sort keys %hash) {
  foreach my $sent (sort {$a<=>$b} keys %{ $hash{$pap} }) {
#        ($hash{$pap}{$sent}{gene_celegans}) &&
    if ( ($hash{$pap}{$sent}{protein_celegans}) &&
         ($hash{$pap}{$sent}{localization_cell_components_090507}) &&
         ($hash{$pap}{$sent}{localization_verbs_090507}) &&
         ($hash{$pap}{$sent}{localization_other_090507}) ) { 
#            my $score = $hash{$pap}{$sent}{gene_celegans} + $hash{$pap}{$sent}{localization_cell_components_090507}
#                        + $hash{$pap}{$sent}{localization_verbs_090507} + $hash{$pap}{$sent}{localization_other_090507};
           my $score = $hash{$pap}{$sent}{protein_celegans} + $hash{$pap}{$sent}{localization_cell_components_090507}
                       + $hash{$pap}{$sent}{localization_verbs_090507} + $hash{$pap}{$sent}{localization_other_090507};
           $good{$pap}{$sent} = $score; }
  } # foreach my $sent (sort keys %{ $hash{$pap} })
} # foreach my $pap (sort keys %hash)

my %sort;
foreach my $pap (sort keys %good) {
  foreach my $sent (sort keys %{ $good{$pap} }) {
    my $score = $good{$pap}{$sent};
#     $sort{$score}{$pap}{$sent}++;
#     $sort{$pap}{$score}{$sent}++;		# sort by paper for kimberly 2007 08 07
    $sort{$pap}{$sent}{$score}++;		# sort by paper and sentence for kimberly 2008 03 06
  } # foreach my $sent (sort keys %{ $good{$pap} })
} # foreach my $pap (sort keys %good)

# $sort{'6'}{'WBPaper00002573'}{'s100'}++;

my $semantic_dir = '/usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans3/Data/annotations/body/semantic/';
my $sentence_dir = '/usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans3/Data/processedfiles/body/';
my $count = 0;

# foreach my $score (sort {$a<=>$b} keys %sort) { # }
# #   next unless ($score == 6);
# # S 6 P WBPaper00002573 S s100 E
# #   last if ($count > 2);
#   foreach my $pap (sort keys %{ $sort{$score} }) { # }
# #     next unless ($pap eq 'WBPaper00002573');
# #     last if ($count > 2);
#     foreach my $sent (sort keys %{ $sort{$score}{$pap} }) { # }

my $titles_and_abstracts;

foreach my $pap (sort keys %sort) {		# sort by paper for kimberly 2007 08 07
#   next unless ($pap eq 'WBPaper00031475');	# to test a specific pap
#   next unless ($pap eq 'WBPaper00005026');	# to test a specific pap
#   next unless ($pap eq 'WBPaper00005030');	# to test a specific pap
#   last if ($count > 10);
  my $sem_file = $semantic_dir . $pap;
  my $sent_file = $sentence_dir . $pap;
  foreach my $sent (sort {$a<=>$b} keys %{ $sort{$pap} }) {
    foreach my $score (sort keys %{ $sort{$pap}{$sent} }) {
#       next unless ($sent eq 's100');
      $count++;
#       last if ($count > 2);
      print "$count\tS $score P $pap S s$sent E\t";
      my ($sent_number) = $sent =~ m/(\d+)/;
      $/ = undef;
      open (IN, "<$sent_file") or warn "Cannot open $sent_file : $!";
      my $all_paper = <IN>;
      close (IN) or warn "Cannot close $sent_file : $!";
      my (@actual_sentences) = split/\n/, $all_paper;
      for (2 .. $sent_number) { shift @actual_sentences; }
      my $actual_sentence = shift @actual_sentences;

      open (IN, "<$sem_file") or warn "Cannot open $sem_file : $!";
      my $all_paper = <IN>;
      close (IN) or warn "Cannot close $sem_file : $!";
      $/ = "\n";
      my (@sentences) = split/### EOS ###/, $all_paper;
      for (2 .. $sent_number) { shift @sentences; }
      my $sentence = shift @sentences;
      unless ($sentence =~ m/### s$sent ###/) { print "ERR $sentence does not match s$sent END\n"; }
      $sentence =~ s/^\n### s$sent ###\n//g;
      my ($parsed_sentence) = &parseSentence($sentence, $actual_sentence);
      print "$parsed_sentence";
#       print "ACTUAL SENTENCE $actual_sentence END ACTUAL SENTENCE\n";
#       print "$sentence\n";
    } # foreach my $sent (sort keys %{ $sort{$score}{$pap} })
#     print "DIVIDER\n\n";
  } # foreach my $pap (sort keys %{ $sort{$score} })

  $sent_file =~ s/\/body\//\/title\//;
  $sem_file =~ s/\/body\//\/title\//;
  $/ = undef;
  if (-e $sent_file) {
    open (IN, "<$sent_file") or warn "Cannot open $sent_file : $!";
    my $actual_title = <IN>;
    close (IN) or warn "Cannot close $sent_file : $!";
    open (IN, "<$sem_file") or warn "Cannot open $sem_file : $!";
    my $markup_title = <IN>;
    close (IN) or warn "Cannot close $sem_file : $!";
    foreach my $key_type (@files) {
      if ($markup_title =~ m/\n$key_type/) { 
        my (@words) = split/## EOA ##/, $markup_title;
        my %filter; 
        foreach my $word (@words) {
          if ($word =~ m/$key_type/) { 
            my ($match) = $word =~ m/## BOA ##\n(.*?)\n\d+/;
            $filter{$match}++; } }
        foreach my $stuff (sort keys %filter) {
          $actual_title =~ s/\b($stuff)\b/<$key_type>$1<\/$key_type>/gi; } } }
    $actual_title =~ s/\n/  /g;
    print "TITLE\t$pap\t$actual_title\n"; }
  else { $titles_and_abstracts .= "TITLE\t$pap\tNO_TITLE"; }

  $sent_file =~ s/\/title\//\/abstract\//;
  $sem_file =~ s/\/title\//\/abstract\//;
  $/ = undef;
  if (-e $sent_file) {
    open (IN, "<$sent_file") or warn "Cannot open $sent_file : $!";
    my $actual_abstract = <IN>;
    close (IN) or warn "Cannot close $sent_file : $!";
    open (IN, "<$sem_file") or warn "Cannot open $sem_file : $!";
    my $markup_abstract = <IN>;
    close (IN) or warn "Cannot close $sem_file : $!";
    foreach my $key_type (@files) {
      if ($markup_abstract =~ m/\n$key_type/) { 
        my (@words) = split/## EOA ##/, $markup_abstract;
        my %filter; 
        foreach my $word (@words) {
          if ($word =~ m/$key_type/) { 
            my ($match) = $word =~ m/## BOA ##\n(.*?)\n\d+/;
            $filter{$match}++; } }
        foreach my $stuff (sort keys %filter) {
          $actual_abstract =~ s/\b($stuff)\b/<$key_type>$1<\/$key_type>/gi; } } }
    $actual_abstract =~ s/\n/  /g;
    print "ABSTRACT\t$pap\t$actual_abstract\n"; }
  else { $titles_and_abstracts .= "ABSTRACT\t$pap\tNO_ABSTRACT"; }
  
#   $sent_file =~ s/\/title\//\/abstract\//;
#   if (-e $sent_file) {
#     open (IN, "<$sent_file") or warn "Cannot open $sent_file : $!";
#     my $all_paper = <IN>;
#     close (IN) or warn "Cannot close $sent_file : $!";
#     $/ = "\n";
#     my $build_abstract = '';
#     my (@sentences) = split/### EOS ###/, $all_paper;
#     foreach my $sentence ( @sentences ) {
# #   unless ($sentence =~ m/### $sent ###/) { print "ERR $sentence does not match $sent END\n"; }
# #   $sentence =~ s/^\n### $sent ###\n//g;
#       my ($parsed_sentence) = &parseWithoutSentence($sentence);
#       if ($parsed_sentence) { $build_abstract .= "$parsed_sentence . "; } }
#     if ($build_abstract) { $titles_and_abstracts .= "ABSTRACT\t$pap\t$build_abstract\n"; } }
#   else { $titles_and_abstracts .= "ABSTRACT\t$pap\tNO_ABSTRACT\n"; }
  
} # foreach my $score (sort keys %sort)

if ($titles_and_abstracts) { print $titles_and_abstracts; }

my $etime = time;

# sub parseWithoutSentence {
#   my ($sentence) = @_;
#   if ($sentence =~ m/### s\d+ ###.*?\n/) { $sentence =~ s/### s\d+ ###.*?\n//g; }
#   my $actual_sentence = '';
#   my (@words) = split/## EOA ##\n## BOA ##/, $sentence;
#   my @new_sent;
#   my %convert_hash;
#   my $convert_count = 0;
#   my %genes; my %components;
#   foreach my $word (@words) {
#     $word =~ s/## BOA ##\s*\n//g;
#     $word =~ s/^\n//g;
#     $word =~ s/\n## EOA ##$//g;
# # print "WORD $word ENDWORD\n";
#     my (@sections) = split/\n/, $word;
#     my $actual_word = shift @sections;
# # print "ACTUALWORD $actual_word ENDACTUALWORD\n";
#     $actual_sentence .= $actual_word . " ";
#     foreach my $key_type (@files) {
#       if ($word =~ m/\n$key_type/) { 
#         $convert_count++;
# #         if ($key_type eq 'gene_celegans') { $genes{$actual_word}++; }
#         if ($key_type eq 'protein_celegans') { $genes{$actual_word}++; }
#         if ($key_type eq 'localization_cell_components_090507') { $components{$actual_word}++; }
#         my $convert_word = "CONVERTIFIER$convert_count";
#         $convert_hash{convertifier}{$convert_word} = "<$key_type>$actual_word<\/$key_type>";
#         $convert_hash{wordifier}{$actual_word} = $convert_word;
#         $actual_sentence =~ s/$actual_word/$convert_word/g; } }
#   } # foreach my $word (@words)
# # print "ASENT $actual_sentence ENDASENT\n";
#   foreach my $convert_word ( sort keys %{ $convert_hash{convertifier} }) {
#     my $actual_word = $convert_hash{convertifier}{$convert_word};
#     $actual_sentence =~ s/$convert_word/$actual_word/g; }
#   my @genes = sort keys %genes; my $genes = join", ", @genes;
#   my @components = sort keys %components; my $components = join", ", @components;
# #   my $return_val = "$genes\t$components\t${actual_sentence}\n";
#   my $return_val = "${actual_sentence}";
#   if ($actual_sentence =~ m/\w+/) { return $return_val; }
#   return ;
# } # sub parseWithoutSentence

sub parseSentence {
  my ($sentence, $actual_sentence) = @_;
  my (@words) = split/## EOA ##\n## BOA ##/, $sentence;
  my @new_sent;
  my %convert_hash;
  my $convert_count = 0;
  my %genes; my %components;
  foreach my $word (@words) {
    $word =~ s/^## BOA ##\n//g;
    $word =~ s/^\n//g;
    $word =~ s/\n## EOA ##$//g;
    my (@sections) = split/\n/, $word;
    my $actual_word = shift @sections;
    foreach my $key_type (@files) {
      if ($word =~ m/\n$key_type/) { 
        $convert_count++;
#         if ($key_type eq 'gene_celegans') { $genes{$actual_word}++; }
        if ($key_type eq 'protein_celegans') { $genes{$actual_word}++; }
        if ($key_type eq 'localization_cell_components_090507') { $components{$actual_word}++; }
        my $convert_word = "CONVERTIFIER$convert_count";
        $convert_hash{convertifier}{$convert_word} = "<$key_type>$actual_word<\/$key_type>";
        $convert_hash{wordifier}{$actual_word} = $convert_word;
        $actual_sentence =~ s/$actual_word/$convert_word/g; } }
  } # foreach my $word (@words)
  foreach my $convert_word ( sort keys %{ $convert_hash{convertifier} }) {
    my $actual_word = $convert_hash{convertifier}{$convert_word};
    $actual_sentence =~ s/$convert_word/$actual_word/g; }
  my @genes = sort keys %genes; my $genes = join", ", @genes;
  my @components = sort keys %components; my $components = join", ", @components;
  my $return_val = "$genes\t$components\t$actual_sentence\n";
  return $return_val;
} # sub parseSentence


my $dtime = $etime - $stime;
print "Time $dtime E\n";

__END__

Sentences at 	: /usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans3/Data/processedfiles/body/WBPaper00001003
Grammar at 	: /usr/local/textpresso/Textpresso_2.0/Data_Processing/celegans3/Data/annotations/body/semantic/WBPaper00001003

