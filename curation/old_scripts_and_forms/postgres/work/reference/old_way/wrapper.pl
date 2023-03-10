#!/usr/bin/perl -w
#
# get the current time to use as timestamp to reference times of execution and
# differentiate files of different times.  
# call cgc_to_endnote.pl, passing in the time, which reads the current version
# of the cgc data from the web, parses it, and creates a time-labeled
# gophbib.endnote.time file.  
# make a diff of the current parsed file (a symbolic link from the last time
# this script was ran) with the new gophbib.endnote.time, and create a diffend
# file with the diffs.
# call insertmaker.pl (passing in time) which checks whether the data is in the
# database and if sets to update the new (different) data, or sets to create new
# entries for new data.  creates insertfile$time.pl which is a script to input
# data to postgreSQL.  
# changes the permissions of the new pl file to be executable.
# executes it.
# moves the gophbib files to the done/ directory
# moves the insertfile$time.pl file to the done/ directory
# deletes the link to the ``current'' parsed file, and recreates it to link to
# the new ``current'' parsed file (gophbib.endnote.time)
# 2002-01-26

my $time = time;
chdir("/home/postgres/work/reference") || die "Cannot go to /home/postgres/work/reference ($!)";


system(`/home/postgres/work/reference/cgc_to_endnote.pl $time`);

  # create diff file of old parsed and new file.
system(`diff /home/postgres/work/reference/current /home/postgres/work/reference/gophbib.endnote.$time > diffend`);

# my $time = '1012081088'; 

system(`/home/postgres/work/reference/insertmaker.pl $time`);

chmod(0755, "/home/postgres/work/reference/insertfile$time.pl");

system(`/home/postgres/work/reference/insertfile$time.pl`);

rename ("/home/postgres/work/reference/gophbib", "/home/postgres/work/reference/done/gophbib.$time");
rename ("/home/postgres/work/reference/gophbib.endnote.$time", "/home/postgres/work/reference/done/gophbib.endnote.$time");
rename ("/home/postgres/work/reference/gophbib.botchlist.$time", "/home/postgres/work/reference/done/gophbib.botchlist.$time");
rename ("/home/postgres/work/reference/insertfile$time.pl", "/home/postgres/work/reference/done/insertfile$time.pl");

unlink ("/home/postgres/work/reference/current");
symlink("/home/postgres/work/reference/done/gophbib.endnote.$time", "/home/postgres/work/reference/current");
