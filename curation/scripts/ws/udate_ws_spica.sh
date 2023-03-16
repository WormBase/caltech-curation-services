#!/bin/sh
# automated update of WS release
# created by Igor Antoshechkin <igor.antoshechkin@caltech.edu>
# modified by Raymond Lee <raymond@caltech.edu>


# FTP_SERVER=ftp.wormbase.org                         # URL of the server
FTP_SERVER=caltech.wormbase.org
WS_DIR=/pub/wormbase/releases/current-development-release            # directory to download
DOWNLOAD_DIR=/home/ws/download/AceDB_download       # where to store downloaded files
LOG_DIR=/home/ws/logs                               # where to store logs
ACEDB_DIR=/home/ws/AceDB/                           # where to install the database
USER=${USER:-$LOGNAME}                              # If USER is not set, use LOGNAME as USER ACeDB INSTALL requires USER to be set but cron ENV may only have LOGNAME.


DOW=`date +%a`              	     	            # Day of the week e.g. Mon
DOM=`date +%d`              		            # Date of the Month e.g. 27
DM=`date +%d%b`                 	            # Date and Month e.g. 27Sep
DMY=`date +%d%b%Y`                                  # Date and Month and Year e.g. 17Mar2005
YMD=`date +%Y%b%d`

if [ ! -d $LOG_DIR ]; then
    mkdir $LOG_DIR
fi

if [ ! -d $DOWNLOAD_DIR ]; then
    mkdir $DOWNLOAD_DIR
fi


LOG="$LOG_DIR/download-$YMD.log"

if [ -e $DOWNLOAD_DIR/models.wrm.* ]; then
#	echo 'model file exists and will be removed' >> $LOG
	rm -f $DOWNLOAD_DIR/models.wrm.*
fi

/usr/bin/ncftpget -R $FTP_SERVER $DOWNLOAD_DIR $WS_DIR/acedb/models.wrm.WS???  > $LOG

MODELS=`ls -1 $DOWNLOAD_DIR | grep models.wrm`

echo "MODELS is" $MODELS

echo "models file on $FTP_SERVER is $MODELS"  >> $LOG
rm -f $DOWNLOAD_DIR/$MODELS

if [ -e $ACEDB_DIR/acedb/$MODELS ]; then
    NOW=`date`
    echo "$NOW : models file up to date, nothing to do"  >> $LOG
    exit
else
    rm -rf $DOWNLOAD_DIR                 ################# for now - testing
    mkdir $DOWNLOAD_DIR
    chmod o-r $DOWNLOAD_DIR  # protect dir from copying while half baked
    NOW=`date`
    echo "download started: $NOW"  >> $LOG

##    /usr/bin/ncftpget -R $FTP_SERVER $DOWNLOAD_DIR $WS_DIR  >> $LOG    ################# for now - testing
    cd $DOWNLOAD_DIR
    wget -r -nH --cut-dirs=3 ftp://$FTP_SERVER$WS_DIR/ >> $LOG
    chmod o+r $DOWNLOAD_DIR   # make folder accessible now it's done updating
    NOW=`date`
    echo "download finished: $NOW"  >> $LOG

    if [ ! -d $ACEDB_DIR ]; then
	mkdir $ACEDB_DIR
    fi

    if [ -e $ACEDB_DIR/acedb/wspec/serverpasswd.wrm ]; then
	cp $ACEDB_DIR/acedb/wspec/serverpasswd.wrm $DOWNLOAD_DIR
    fi

    if [ -e $ACEDB_DIR/acedb/wspec/serverconfig.wrm ]; then
	cp $ACEDB_DIR/acedb/wspec/serverconfig.wrm $DOWNLOAD_DIR
    fi

    echo "removing old $ACEDB_DIR directories..."  >> $LOG
    rm -rf $ACEDB_DIR/acedb
    rm -rf $ACEDB_DIR/genomes
    rm -rf $ACEDB_DIR/ONTOLOGY
    rm -f $ACEDB_DIR/*.gz        # not really needed
    rm -f $ACEDB_DIR/*.bz2       # not really needed
    rm -rf $ACEDB_DIR/species
    rm -rf $ACEDB_DIR/COMPARATIVE_ANALYSIS

    echo "cp -rp $DOWNLOAD_DIR/current-development-release/* $ACEDB_DIR"  >> $LOG
#    cp -rp $DOWNLOAD_DIR/current-development-release/* $ACEDB_DIR
    rsync -a $DOWNLOAD_DIR/current-development-release/* $ACEDB_DIR
    cd $ACEDB_DIR/acedb

    echo 'y' > install_input
    echo '' >> install_input
    echo 'n' >> install_input

    chmod +x INSTALL
    /usr/bin/env USER="$USER" ./INSTALL < install_input  2>&1 >> $LOG

    if [ -e $DOWNLOAD_DIR/serverpasswd.wrm ]; then
	cp $DOWNLOAD_DIR/serverpasswd.wrm $ACEDB_DIR/acedb/wspec
    fi
    if [ -e $DOWNLOAD_DIR/serverconfig.wrm ]; then
	cp $DOWNLOAD_DIR/serverconfig.wrm $ACEDB_DIR/acedb/wspec
    fi

#    echo "rm -f $ACEDB_DIR/acedb/database.*.gz"  >> $LOG
#    rm -f $ACEDB_DIR/acedb/database.*.gz   # remove downloaded database files

#    rm -rdf $DOWNLOAD_DIR                 ################# for now - testing

    NOW=`date`
    echo "installation finished: $NOW"  >> $LOG
fi