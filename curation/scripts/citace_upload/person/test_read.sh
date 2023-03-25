# cd /home/acedb/ts
# export ACEDB=/home/acedb/ts
cd /usr/caltech_curation_files/wdemo
export ACEDB=/usr/caltech_curation_files/wdemo
#Start reading files
# /home/acedb/bin/tace -tsuser 'cecilia' <<END_TACE
/acedb/bin.LINUX_64/tace -tsuser 'cecilia' <<END_TACE
Read-models
y
Parse /usr/caltech_curation_files/cecilia/citace_upload/persons.ace
Parse /usr/caltech_curation_files/cecilia/citace_upload/laboratories.ace
Parse /usr/caltech_curation_files/cecilia/citace_upload/collaborators.ace
quit
n
END_TACE
#End reading files.

# Parse /home/acedb/cecilia/citace_upload/persons.ace
# Parse /home/acedb/cecilia/citace_upload/laboratories.ace
# Parse /home/acedb/cecilia/citace_upload/collaborators.ace

# if want to wipe out db after saving do :
# rm /home/acedb/ts/database/ACEDB.wrm
# delete acedb.wrm to reset db
#
# if had wiped out db, need to reinitialize the system with a leading ``y'' before Read-models
