#!/usr/bin/env bash

date=$(date -u +"%Y%m%d_%H%M%S")
mkdir "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}"
/bin/agr_referencefile_bulk_uploader WB > "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/results.log"
grep "API_CALL_STATUS: success" "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/results.log" > "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/success.log"
grep "API_CALL_STATUS: error" "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/results.log" > "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/error.log"

cat "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/success.log" | while read line
do
  file_to_remove=$(echo $line | grep -o "FILE:.*" | cut -d " " -f 2 | sed 's/\/usr\/files_to_upload\///')
  rm "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/files/${file_to_remove}"
  if [[ "$(echo "${file_to_remove}" | grep "/" | wc -l)" == "1" ]]
  then
    dir_name=$(echo "${file_to_remove}" | cut -d "/" -f1)
    dir_path="${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/files/${dir_name}"
    if [[ -z $(ls -A "${dir_path}") ]]
    then
      rmdir "${dir_path}"
    fi
  fi
done