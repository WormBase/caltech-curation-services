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

### Email (AWS SES)

All outgoing mail - form confirmations, curator notifications, cron job error
reports, the webinar and community curation mailings - goes through
`Jex::mailer` in `curation/scripts/perl_modules/Jex.pm`, which talks to AWS SES
over SMTP.

Set these two in the `.env` file that `ENV_FILE_PATH` points at, using the SES
SMTP credentials from the textpresso AWS account:

```
EMAIL_SMTP_USER=<SES smtp username>
EMAIL_PASSWD=<SES smtp password>
```

`EMAIL_SMTP_USER` is an opaque SES credential, not an address, so the visible
sender comes from `EMAIL_FROM` instead. `EMAIL_HOST`, `EMAIL_PORT`,
`EMAIL_FROM` and `EMAIL_REPLY_TO` are optional; when empty, `Jex.pm` uses
`email-smtp.us-east-1.amazonaws.com`, port 465,
`WormBase Curation <no-reply@caltech-curation.textpressolab.com>` and
`outreach@wormbase.org`. `EMAIL_FROM` has to be an SES-verified identity -
`textpressolab.com` is verified as a parent domain, so any subdomain of it
works without further DNS setup.

`Jex.pm` is copied into the image by `curation/Dockerfile`, it is not bind
mounted, so a change to the mailer needs a rebuild rather than a restart:

```bash
docker compose up -d --build curation
```

To check the credentials, send a test message through the same code path the
forms use:

```bash
make test-mailer TO=you@example.org                        # on the server
make test-mailer TO=you@example.org COMPOSE_ARGS='--env-file .env.local'   # on a laptop
```

`make test-mailer` uses `run --rm --no-deps`, so it works whether or not the
curation service is up. The equivalent by hand:

```bash
docker compose run --rm --no-deps \
  curation /usr/lib/scripts/test_mailer.pl -e you@example.org
```

To try credentials without editing the env file first, pass them straight in.
`Dotenv` does not overwrite variables that are already in the environment, so
these win over the file:

```bash
docker compose exec -e EMAIL_SMTP_USER -e EMAIL_PASSWD \
  curation /usr/lib/scripts/test_mailer.pl -e you@example.org
```

Do not add the `EMAIL_*` variables to the `curation` service's `environment:`
block in `docker-compose.yml`. Because `Dotenv` yields to whatever is already
set, an empty value there would shadow the real one in the env file.

Every send is logged to the apache or cron log with a `mailer:` prefix, whether
it succeeded or failed, so an outage is visible instead of silent.
