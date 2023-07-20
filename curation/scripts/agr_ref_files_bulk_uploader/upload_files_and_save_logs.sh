#!/usr/bin/env bash

date=$(date -u +"%Y%m%d_%H%M%S")
mkdir "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}"
/bin/agr_referencefile_bulk_uploader WB > "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/results.log"
grep "API_CALL_STATUS: success" "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/results.log" > "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/success.log"
grep "API_CALL_STATUS: error" "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/results.log" > "${CALTECH_CURATION_FILES_INTERNAL_PATH}/daniel/abc_upload/logs/${date}/error.log"