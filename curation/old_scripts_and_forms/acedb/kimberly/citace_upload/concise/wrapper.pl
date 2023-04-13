#!/usr/bin/perl

# Dump concise description data to old/concise_dump.date.hour.ace
# and symlink to /home/postgres/public_html/cgi-bin/data/concise_dump_new.ace
# for cronjob for Erich.
# 0 2 * * wed /home/postgres/work/citace_upload/concise/wrapper.pl
# Matches script on altair at /home/citace/cronjobs/copyConciseAndGOTerms.pl
# 2005 09 15
#
# moved to 0 2 * * fri and consolidated under /home/postgres/work/citace_upload/wrapper.sh
# 2009 04 09
#
# using OA dumper.  2011 09 26


use Jex;

my $date = &getSimpleSecDate();

my $directory = '/home/postgres/work/citace_upload/concise';
my $outfile = '/home2/postgres/work/citace_upload/concise/old/concise_dump.' . $date . '.ace';

chdir($directory) or die "Cannot go to $directory ($!)";

`/home/postgres/work/citace_upload/concise/dump_concise.pl > $outfile`;
# `/home/postgres/work/citace_upload/concise/get_concise_to_ace_new_evidence_fields.pl > $outfile`;
# `/home/postgres/work/citace_upload/concise/get_concise_to_ace_new_evidence_fields.pl > /home/postgres/public_html/cgi-bin/data/concise_dump_new.ace`;

my $location_of_latest = '/home/postgres/public_html/cgi-bin/data/concise_dump_new.ace';
unlink ("$location_of_latest") or die "Cannot unlink $location_of_latest : $!";       # unlink symlink to latest
symlink("$outfile", "$location_of_latest") or warn "cannot symlink $location_of_latest : $!";


