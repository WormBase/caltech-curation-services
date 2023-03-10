#!/usr/bin/perl -w
# Script finds anatomy terms in wormatlas *.htm* files and ranks them
use strict;

# get the anatomy term names
my $anatomy_file = "./toindex/anatomy_terms.txt";
open (IN, "<$anatomy_file") or die ("Died. Please provide anatomy terms in file: $anatomy_file\n");
my %anatomy_terms;
my $c = 0;
while (my $line = <IN>) {
	if ($line =~ /^(\S+)\t\"(.+?)\"/) {
		my $id = $1;
		my $name = $2;
		$name = escapeChars($name);
	
		$anatomy_terms{$name}{$id} = 1;
		$c++;
	}
}
close (IN);
#print "Loaded $c items\n";

my $base_dir = "./toindex/wormatlas/";
my %result;
indexPages($base_dir, \%result);
outputResults(\%result);

sub indexPages {
	my $dir = shift;
	my $presult = shift;

	open (OUT, ">program_output_temp.txt");

	my @files;
	# if dir names have spaces in them!
	if ($dir =~ / /) {
		@files = <"$dir"/*>;
	} else { 
		@files = <$dir/*>;
	}

	for my $f (@files) {
		# recurse if $f is directory
		if (-d $f) {
			indexPages($f, $presult);
		} else { # check if file is *frameset.html file
			my @e = split(/\//, $f);
			my $filename = pop @e;
			if ($filename =~ /.*frameset\.htm/i) {
				print  OUT "f = $f\n";
				# the file we are looking at, $f, may not be the file that has the data.
				# it has '<frame src=' in it and refers to another mainframe html file.
				# if this is the case, then get that file, which has the data.

				my $f_data = $f; # this will be the mainframe.htm file
				open (IN, "<$f") or die ("Died: could not open $f for reading\n");
				while (my $html_line = <IN>) {
					chomp ($html_line);
					
					if ($html_line =~ /\<frame src=\"leftframe\.htm\"/) {
						next; # skip if leftframe.htm
					} elsif ($html_line =~ /\<frame src=\"(.*\.html?)\"/) { # then open the mainframe file
						my $subfilename = $1;
						$f_data =~ s/(.+)\/(.+?)$/$1\/$subfilename/;
						print OUT "f_data = $f_data\n";

						open (IN_DATA, "<$f_data") or die ("Died: could not open $f_data for reading\n");
						while (my $line = <IN_DATA>) {
							$line = escapeChars($line);
							# remove html tags
							$line =~ s/\<.+?\>//g;
							# next line if line is empty after removing tags
							next if ($line =~ /^\s*$/);

							# check if the line has any anatomy terms
							for my $term (keys %anatomy_terms) {
								while ($line =~ /(^|\s|\(|\[|\{|\,|\;|\'|\`|\&|\.)$term($|\s|\)|\]|\}|\,|\;|\'|\`|\&|\.)/g) {
									print OUT "$term\n";
	
									for my $id (keys %{$anatomy_terms{$term}}) {
										if (defined($$presult{$term}{$id}{$f})) {
											$$presult{$term}{$id}{$f}++;
										} else {
											$$presult{$term}{$id}{$f} = 1;
										}
									}
								}
							}
						}
						close IN_DATA;
					} else {
						$html_line = escapeChars($html_line);
						# remove html tags
						$html_line =~ s/\<.+?\>//g;
						# next line if line is empty after removing tags
						next if ($html_line =~ /^\s*$/);

						# check if the line has any anatomy terms
						for my $term (keys %anatomy_terms) {
							while ($html_line =~ /(^|\s|\(|\[|\{|\,|\;|\'|\`|\&|\.)$term($|\s|\)|\]|\}|\,|\;|\'|\`|\&|\.)/g) {
								print  OUT "$term\n";
	
								for my $id (keys %{$anatomy_terms{$term}}) {
									if (defined($$presult{$term}{$id}{$f})) {
										$$presult{$term}{$id}{$f}++;
									} else {
										$$presult{$term}{$id}{$f} = 1;
									}
								}
							}
						}
					}
				}
				print OUT  "---------------------------------------------------------------------------------\n";
			}
		}
	}
	return;

}

sub outputResults {
	my $presult = shift;

	open (OUT, ">output_temp.html");
	for my $t (sort keys %{$presult}) {
		
		for my $id (keys %{$$presult{$t}}) {
			print OUT "$t\t$id\t";
		
			for my $f (keys %{$$presult{$t}{$id}}) {

				# sort the output in descending order
				my $big_f = $f;
				my $big_n = $$presult{$t}{$id}{$f};
		
				for my $f2 (keys %{$$presult{$t}{$id}}) {
					if ($$presult{$t}{$id}{$f2} > $big_n) {
						$big_f = $f2;
						$big_n = $$presult{$t}{$id}{$f2};
					}
				}
				
				my @e = split(/\//, $big_f);
				my $fn = pop @e;
				
				my $html_page = $big_f;
				$html_page =~ s/^\.\/toindex\/wormatlas\//http:\/\/www\.wormatlas\.org\//;
	
				print OUT "\<a href=\"$html_page\"\>$fn\<\/a\>\(" . $big_n ."\)\t";
	
				delete $$presult{$t}{$id}{$big_f};
			}
			print OUT "<br/>\n";
		}
	}

	return;
}

sub escapeChars {
	my $name = shift;
	$name =~ s/\./\\\./g;
	$name =~ s/\(/\\\(/g;
	$name =~ s/\)/\\\)/g;
	return $name;
}
