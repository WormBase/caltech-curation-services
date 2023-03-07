# caltech-curation-services

## aCeDB

# run aCeDB using docker on your local computer (works on Linux only)

You can specify the location of a local directory that will be mounted from your computer to the aCeDB docker container by modifying the following variables in the `.env` file:

CALTECH_CURATION_FILES_INTERNAL_PATH=<path to local directory on your computer>
CALTECH_CURATION_FILES_EXTERNAL_PATH=<location inside the docker container where the directory will be mounted>

Once these variables are set, start the docker container with the following command:

```bash
$ make start-acedb
```

## Setup

### Grafana

Create grafana/grafana.ini file and modify it with custom config. For example, modify the smtp section to be able to send out email alert notifications. 

grafana/grafana_original.ini contains the original default settings.
