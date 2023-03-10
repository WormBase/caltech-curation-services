#!/usr/bin/perl

# automated update of WS release
# created by Igor Antoshechkin <igor.antoshechkin@caltech.edu>
# edited for mangolassi  2009 03 23
#
# updated for new tazendra in non-backup directory  2009 04 20
#
# set to cronjob  2009 03 26
# 0 3 * * * /media/disk2/acedb/update_ws_tazendra.cron
#
# replaced shell script since that wasn't working  2009 09 01
# 0 3 * * * /home/acedb/update_ws_tazendra.pl
#
# Wen is running the equivalent of this on spica now and scping files over.
# 2022 02 06


use strict;
use Jex;


# DOWNLOAD_DIR=/home/ws/download/AceDB_download       # where to store downloaded files
# LOG_DIR=/home/ws/logs                               # where to store logs
# ACEDB_DIR=/home/ws/AceDB/                           # where to install the database
# DOWNLOAD_DIR=/home2/acedb/download/AceDB_download   # where to store downloaded files

my $FTP_SERVER = 'ftp.sanger.ac.uk';				# URL of the server
my $WS_DIR = '/pub/wormbase/development_release';		# directory to download
my $DOWNLOAD_DIR = '/home2/acedb/download/AceDB_download';	# where to store downloaded files
my $LOG_DIR = '/home2/acedb/ws/logs';				# where to store logs
my $ACEDB_DIR = '/home2/acedb/ws';				# where to install the database
# my $DOWNLOAD_DIR = '/home3/acedb/download/AceDB_download';	# home3 no longer exists
# my $LOG_DIR = '/home3/acedb/ws/logs';				
# my $ACEDB_DIR = '/home3/acedb/ws';			

# DOW=`date +%a`              	     	            # Day of the week e.g. Mon
# DOM=`date +%d`              		            # Date of the Month e.g. 27
# DM=`date +%d%b`                 	            # Date and Month e.g. 27Sep
# DMY=`date +%d%b%Y`                                  # Date and Month and Year e.g. 17Mar2005

my $date = &getSimpleDate();

if ( ! -d $LOG_DIR ) { `mkdir $LOG_DIR`; }

my $LOG = "$LOG_DIR/download-$date.log";

my (@files) = <$DOWNLOAD_DIR/models.wrm.*>;		# remove downloaded models.wrm.*
foreach (@files) { unlink( $_ ); }

print "/usr/bin/ncftpget -R $FTP_SERVER $DOWNLOAD_DIR $WS_DIR/acedb/models.wrm.* &> $LOG\n";
`/usr/bin/ncftpget -R $FTP_SERVER $DOWNLOAD_DIR $WS_DIR/acedb/models.wrm.* &> $LOG`;
my $MODELS = `ls -1 $DOWNLOAD_DIR | grep models.wrm`;
chomp $MODELS;						# get rid of newline
unlink ("${DOWNLOAD_DIR}/${MODELS}");			# get rid of downloaded models.wrm file

`echo "models file on $FTP_SERVER is $MODELS" >> $LOG`;
print "models file on $FTP_SERVER is $MODELS\n" ;



my $now = &getSimpleSecDate();
if ( -e "${ACEDB_DIR}/acedb/${MODELS}" ) {
  `echo "$now : models file up to date, nothing to do" >> $LOG`;
  print "$now : models file up to date, nothing to do\n";
  exit;
} else {
  my ($release) = $MODELS =~ m/(WS\d+)/; my $temp_release = 'releases/' . $release;
  $WS_DIR =~ s/development_release/$temp_release/;

  print "/usr/bin/ncftpget -R $FTP_SERVER $DOWNLOAD_DIR $WS_DIR >> $LOG\n";
  `/usr/bin/ncftpget -R $FTP_SERVER $DOWNLOAD_DIR $WS_DIR >> $LOG`;    # UNCOMMENT to get from sanger

  $now = &getSimpleSecDate();
  `echo "download finished: $now" >> $LOG`;

  if ( ! -d $ACEDB_DIR ) { `mkdir $ACEDB_DIR`; }
  if ( -e "${ACEDB_DIR}/acedb/wspec/serverpasswd.wrm" ) {
    `cp $ACEDB_DIR/acedb/wspec/serverpasswd.wrm $DOWNLOAD_DIR`;
  }
  if ( -e "${ACEDB_DIR}/acedb/wspec/serverconfig.wrm" ) {
    `cp $ACEDB_DIR/acedb/wspec/serverconfig.wrm $DOWNLOAD_DIR`;
  }
 
  `echo "removing old $ACEDB_DIR directories..." >> $LOG`;
  `rm -rdf $ACEDB_DIR/acedb`;
  `rm -rdf $ACEDB_DIR/genomes`;
  `rm -rdf $ACEDB_DIR/ONTOLOGY`;
#     rm -f $ACEDB_DIR/*.gz        # not really needed
#     rm -f $ACEDB_DIR/*.bz2       # not really needed

  `echo "cp -rp $DOWNLOAD_DIR/$release/* $ACEDB_DIR" >> $LOG`;
  `cp -rp $DOWNLOAD_DIR/$release/* $ACEDB_DIR`;	# UNCOMMENT to copy downloaded content
#   `cd $ACEDB_DIR/acedb`;				# doesn't work for perl, next call will no longer have that directory
  my $directory_to_install = $ACEDB_DIR . '/acedb';	# need to be in directory to install for INSTALL to work
  chdir($directory_to_install) or die "Cannot go to $directory_to_install ($!)";


#     echo 'y' > install_input
#     echo '' >> install_input
#     echo 'n' >> install_input


  my $install_file = "$ACEDB_DIR/acedb/INSTALL"; 
  `chmod +x $install_file`;
#   print "$install_file < $ACEDB_DIR/install_input >> $LOG\n";
  `$install_file < $ACEDB_DIR/install_input >> $LOG`;

  if ( -e "${DOWNLOAD_DIR}/serverpasswd.wrm" ) {
    `cp $DOWNLOAD_DIR/serverpasswd.wrm $ACEDB_DIR/acedb/wspec`;
  }
  if ( -e "${DOWNLOAD_DIR}/serverconfig.wrm" ) {
    `	cp $DOWNLOAD_DIR/serverconfig.wrm $ACEDB_DIR/acedb/wspec`;
  }
 
  `echo "rm -f $ACEDB_DIR/acedb/database.*.gz" >> $LOG`;
  `rm -f $ACEDB_DIR/acedb/database.*.gz`;		# remove downloaded database files

#     rm -rdf $DOWNLOAD_DIR                 ################# for now - testing

  $now = &getSimpleSecDate();
  `echo "installation finished: $now" >> $LOG`;

#   `/home/acedb/cron/populate_gin.pl`;			# get rid of this when we switch to populate_pg_from_ws.pl  2013 10 18  done 2013 10 21

  `/home/acedb/cron/dump_from_ws.sh`;			# dump .ace files from WS to update postgres tables
#   my $dateOfWsDumpFile = '/home3/acedb/cron/dump_from_ws/files/latestDate';
  my $dateOfWsDumpFile = '/home2/acedb/cron/dump_from_ws/files/latestDate';		# home3 no longer exists 2014 11 25
  `echo "$date" >> $dateOfWsDumpFile`;			# set a file to track the date of when the last dump happened for populate_pg_from_ws.pl to trigger off of.  2013 10 18
}

