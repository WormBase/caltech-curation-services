# #!/bin/csh
# setenv ACEDB /home/citpub/CitaceMirror/ts/
cd /home/acedb/ts
export ACEDB=/home/acedb/ts
#Start reading files
/home/acedb/bin/tace -tsuser 'cecilia' <<END_TACE
Read-models
y
Parse /home/acedb/cecilia/citace_upload/persons.ace
Parse /home/acedb/cecilia/citace_upload/laboratories.ace
Parse /home/acedb/cecilia/citace_upload/collaborators.ace
quit
n
END_TACE
#End reading files.


# if want to wipe out db after saving do :
# rm /home/acedb/ts/database/ACEDB.wrm
# delete acedb.wrm to reset db
#
# if had wiped out db, need to reinitialize the system with a leading ``y'' before Read-models
