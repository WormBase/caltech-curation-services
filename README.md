# Caltech Curation Services

The curation platform the WormBase group at Caltech runs for *C. elegans* literature
and biological data. It is the software behind the forms curators use every day, the
public submission forms the worm community fills in, and the nightly and weekly jobs
that push curated data out to **citace** (and from there into the WormBase release)
and to the **Alliance of Genome Resources**.

| | |
| --- | --- |
| Production | <https://caltech-curation.textpressolab.com> |
| Staging / dev | <https://caltech-curation-dev.textpressolab.com> |
| Legacy alias | <http://caltech.wormbase.org> (static files, FTP `pub/`, virtualworm) |
| Repository | `WormBase/caltech-curation-services` |
| Hosting | two AWS EC2 instances (`us-east-1`), Docker Compose, no CI/CD |

**If you curate data**, read [Part 1](#part-1--what-the-services-are). It describes what
the services are, how they fit together and where your annotations end up.

**If you maintain or deploy the system**, read [Part 2](#part-2--running-and-deploying-it).

---

# Part 1 — What the services are

## The shape of the system

Everything revolves around a single PostgreSQL database (`caltech_curation`). Forms
write into it, scheduled jobs read out of it and ship the data onward.

```
  community authors                  curators
  (public forms, no login)      (curator forms + OA, password)
          │                                  │
          └──────────────┬───────────────────┘
                         ▼
             ┌────────────────────────┐
             │   PostgreSQL           │   pap_* papers   two_* people
             │   caltech_curation     │   obo_* ontologies   <dt>_* datatypes
             │   (+ *_hst history)    │
             └───────────┬────────────┘
                         │  nightly / weekly cron jobs
        ┌────────────────┼─────────────────┬──────────────────┐
        ▼                ▼                 ▼                  ▼
   .ace dumps       Alliance (ABC)     PubMed / ORCID     email to curators
   → citace         literature +       CrossRef ingest    and submitters
   → WormBase       topic/entity       (incoming)
     release        tags
```

Two properties are worth knowing because they shape everything else:

* **Nothing is ever really overwritten.** Almost every table has a `_hst` twin that
  records who changed what and when. If an annotation looks wrong, its history is
  still there.
* **There is no "save and publish" step.** Data leaves the database on a schedule —
  the citace dumps and the Alliance uploads run from cron, mostly overnight
  (see [Where curated data goes](#where-curated-data-goes)).

## Two doors into the system

Every page in the system is one CGI script, and the system publishes its own index of
them: the **[site map](https://caltech-curation.textpressolab.com/pub/cgi-bin/index.cgi)**
is generated at request time by listing the scripts on disk, so it is always current
and always lists every form with its URL and a one-line description. The tables below
are the curated tour; the site map is the complete list.

### Public forms — no login

Linked from wormbase.org and used by the community. Submissions generally land in
PostgreSQL *and* send mail to the relevant curators.

| Form | What it is for |
| --- | --- |
| [phenotype](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/phenotype.cgi), [allele_phenotype](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/allele_phenotype.cgi) | community phenotype submission |
| [expr_pattern](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/expr_pattern.cgi) | expression pattern submission |
| [gene_name](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/gene_name.cgi), [gene_sanitizer](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/gene_sanitizer.cgi) | request a gene/gene-class name; resolve dead or renamed genes |
| [strain_request](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/strain_request.cgi), [wild_isolate](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/wild_isolate.cgi) | strain requests and wild isolate reports |
| [2_pt_data](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/2_pt_data.cgi), [multi_pt](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/multi_pt.cgi), [df_dp](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/df_dp.cgi), [rearrangement](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/rearrangement.cgi), [breakpoint](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/breakpoint.cgi), [allele_sequence](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/allele_sequence.cgi) | classic mapping / rearrangement / allele submission forms |
| [person](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/person.cgi), [person_name](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/person_name.cgi), [person_lineage](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/person_lineage.cgi) | people update their own WBPerson record and lineage |
| [simplemine](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/simplemine.cgi), [agr_simplemine](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/agr_simplemine.cgi), [fpkmmine](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/fpkmmine.cgi) | batch gene lookups; RNA-seq FPKM lookups |
| [simplefind](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/simplefind.cgi), [expression_dataset_locator](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/expression_dataset_locator.cgi), [EDLMaca](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/EDLMaca.cgi) | expression dataset / SPELL queries |
| [reagent_help](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/reagent_help.cgi) | reagent lookups |
| [paper_display](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/paper_display.cgi) | read-only view of paper records |
| [uniprot](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/uniprot.cgi) | curated data with PMIDs, for UniProt |
| [datatype_objects](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/datatype_objects.cgi), [abc_readonly_api](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/abc_readonly_api.cgi) | lookup/autocomplete APIs used by other tools |
| [generic](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/generic.cgi) | assorted public tasks (show your IP, verify paper connections) |
| [webinar](https://caltech-curation.textpressolab.com/pub/cgi-bin/forms/webinar.cgi) | webinar sign-up |

### Curator forms — password required

Protected by an HTTP Basic password prompt (the shared "tazendra" password, served
from an Apache password file on the host). The links below will ask for it. Once you
are through, the form remembers *which* curator you are from a browser cookie — your
WBPerson "two" number — and stamps it on everything you change. There are no
individual application logins, so a browser that has forgotten its cookie will ask you
to pick your name again.

| Form | What it is for |
| --- | --- |
| [ontology_annotator](https://caltech-curation.textpressolab.com/priv/cgi-bin/oa/ontology_annotator.cgi) | **the OA** — the main annotation tool, see below |
| [paper_editor](https://caltech-curation.textpressolab.com/priv/cgi-bin/paper_editor.cgi) | edit paper records: authors, journal, abstract, identifiers, flags |
| [curation_status](https://caltech-curation.textpressolab.com/priv/cgi-bin/curation_status.cgi) | per-paper, per-datatype curation progress across curators |
| [community_curation_tracker](https://caltech-curation.textpressolab.com/priv/cgi-bin/community_curation_tracker.cgi) | track author submissions and generate the mass-mail list |
| [anatomy_function](https://caltech-curation.textpressolab.com/priv/cgi-bin/anatomy_function.cgi) | anatomy function curation |
| [new_objects](https://caltech-curation.textpressolab.com/priv/cgi-bin/new_objects.cgi), [temp_objects](https://caltech-curation.textpressolab.com/priv/cgi-bin/temp_objects.cgi), [nameserver_api](https://caltech-curation.textpressolab.com/priv/cgi-bin/nameserver_api.cgi) | new/temporary object IDs via the WormBase name service |
| [interaction_ticket](https://caltech-curation.textpressolab.com/priv/cgi-bin/interaction_ticket.cgi), [journal_paper_ticket](https://caltech-curation.textpressolab.com/priv/cgi-bin/journal_paper_ticket.cgi) | reserve new interaction IDs / WBPaper IDs |
| [person_editor](https://caltech-curation.textpressolab.com/priv/cgi-bin/cecilia/person_editor.cgi), [lab_editor](https://caltech-curation.textpressolab.com/priv/cgi-bin/cecilia/lab_editor.cgi) | person and laboratory records |
| [species_taxon_editor](https://caltech-curation.textpressolab.com/priv/cgi-bin/species_taxon_editor.cgi) | curated species/taxon list |
| [gene_class_display](https://caltech-curation.textpressolab.com/priv/cgi-bin/gene_class_display.cgi), [wbgene_info](https://caltech-curation.textpressolab.com/priv/cgi-bin/wbgene_info.cgi) | gene class and WBGene reference tables |
| [referenceform](https://caltech-curation.textpressolab.com/priv/cgi-bin/referenceform.cgi) | direct queries against the curation database |
| [agr_reffile_upload](https://caltech-curation.textpressolab.com/priv/cgi-bin/agr_reffile_upload.cgi) | push paper PDFs and supplements to the Alliance ABC |
| [omit_form](https://caltech-curation.textpressolab.com/priv/cgi-bin/omit_form.cgi) | IPs / people / addresses to skip in automated mailings |

On the dev server the same pages live under
`https://caltech-curation-dev.textpressolab.com/` with identical paths.

## The Ontology Annotator (OA)

Most day-to-day annotation happens in one form, the
[OA](https://caltech-curation.textpressolab.com/priv/cgi-bin/oa/ontology_annotator.cgi). It is a single generic
spreadsheet-like interface that is re-skinned per **datatype**: the columns, the
ontologies used for autocomplete and the validation rules all come from a
configuration table rather than from separate code per datatype.

Datatypes currently configured (three-letter code → label):

| | | | |
| --- | --- | --- | --- |
| `abp` antibody | `app` phenotype | `cns` construct | `con` concise description |
| `dis` disease | `dit` disease term | `exp` expression pattern | `gcl` gene class |
| `gno` genotype | `gop` GO | `grg` gene regulation | `int` interaction |
| `mop` molecule | `mov` movie | `pic` picture | `pro` topic |
| `prt` process term | `ptg` / `trp` transgene | `rna` RNAi | `sqf` sequence feature |

Practical consequences of that design:

* Adding a column or a new datatype is a configuration change, not a new form.
* The ontologies behind the autocompletes are refreshed nightly from the source OBO
  files, so a term that was added upstream today is usually selectable tomorrow.
* Each row records its curator and timestamp, and keeps its history.

Developer-facing documentation for the OA lives next to the code, in
`curation/website/priv/cgi-bin/oa/docs/` (start at `ontology_annotator_CGI.html`).

## Where curated data goes

| Destination | How | Roughly when |
| --- | --- | --- |
| **citace** (→ AceDB → WormBase release) | `.ace` files written by `curation/scripts/citace_upload/*` | papers Tue–Sat 02:00; other datatypes on their own schedules |
| **Alliance (ABC / literature service)** | `curation/scripts/agr_upload/pap_papers/*`, plus reference-file uploads | literature dump Tue–Sat 05:00; topic/entity jobs weekly |
| **Incoming papers** | PubMed XML download and matching | nightly 01:00 |
| **Ontologies** | OBO refresh into `obo_*` tables | nightly 20:00 |
| **Statistics / dashboards** | curation stats jobs → Grafana | daily / monthly |
| **Email** | form confirmations, curator notifications, community-curation and webinar mailings | on submission, or from the job that sends them |

All of these run inside the curation container from `curation/crontab`, and **only on
the production host** — the dev host deliberately runs no cron jobs.

## When something looks wrong

* A form throws an error, or a page will not load → it is a server-side problem;
  report it with the URL and roughly the time, so the Apache log can be matched up.
* An annotation is missing or looks wrong → the `_hst` history tables can say who
  changed it and when; ask a developer to look it up.
* Something you curated has not appeared in WormBase → check the schedule above
  first; most exports run overnight and the release itself is monthly.

---

# Part 2 — Running and deploying it

## Stack

Perl 5.18 CGI on Apache, PostgreSQL 11, all under Docker Compose behind an nginx
reverse proxy. There is no application framework and no test suite; the CGI scripts
are the application.

| Compose service | Image / build | What it does |
| --- | --- | --- |
| `curation` | built from `curation/Dockerfile` | Apache + all CGI scripts, cron jobs, AceDB & AcePerl, restic, sshd |
| `db` | `postgres:11` | the `caltech_curation` database |
| `reverse_proxy` | built from `reverse_proxy/Dockerfile` | nginx + certbot, terminates TLS for this **and other Textpresso services on the same box** |
| `grafana`, `prometheus`, `alertmanager` | upstream images | dashboards and alerting |
| `postgres_prom_exporter`, `grok_exporter_*` | upstream / local build | Postgres metrics; log-scraping metrics for AFP, VFP, antibody, expression-cluster, e-mail-extraction pipelines |
| `jenkins` | `jenkins/jenkins:lts` | shared build server for *other* WormBase/Textpresso projects, not for this repo |
| `acedb` | built from `acedb/` | optional local AceDB GUI (Linux + X11 only) |

## Repository layout

```
curation/
  Dockerfile                     the curation image
  container_startup_setup.sh     runs at container start: restic init, apache env,
                                 sshd, and (prod only) installs the crontab
  crontab                        every scheduled job, grouped by curator
  website/
    apache_conf/                 vhosts; httpd.conf defines /pub, /priv, /files
    pub/cgi-bin/forms/           public forms (no auth)
    priv/cgi-bin/                curator forms (HTTP Basic)
      oa/                        the Ontology Annotator + its docs
      cecilia/                   person and lab editors
      ace/                       AceDB-backed browse/query CGIs
  scripts/
    perl_modules/                Jex.pm, ace_dumper.pm, pap_match.pm
    citace_upload/               .ace dumpers, one directory per datatype
    agr_upload/                  Alliance literature and topic/entity uploads
    pgpopulation/                jobs that populate/refresh database tables
    cronjobs/                    pg dumps, stats, lineage, header refresh
    community_curation/          mass-mail generation
    get_stuff/, parsings/        per-curator one-off and recurring extractions
  user_files/                    files forms/scripts expect, with per-file readmes
  old_scripts_and_forms/         archive of pre-Docker tazendra scripts (not wired up)
db/                              postgresql.conf and pg_hba.conf
reverse_proxy/                   nginx configs (prod and dev) + certbot cron
prometheus/, grafana/            monitoring configuration
acedb/                           AceDB container
```

## Configuration

Everything is driven by a single env file. The one committed at the repo root is a
**local-development default**, not the production configuration — the real ones live
outside the repo on the servers (see [Deploying](#deploying)).

Groups of variables:

* `PSQL_*` — database name, host (`curation_db` inside the network), port, credentials.
* `HOST_NAME`, `THIS_HOST`, `THIS_HOST_AS_BASE_URL` — how the app builds its own URLs.
  Get `THIS_HOST_AS_BASE_URL` wrong and stylesheets, headers and form links break.
* `ENV_STATE` — `prod` or `dev`. **`prod` is what turns cron on**, and it selects the
  production nginx config in the reverse proxy.
* `SRC_DIR_PATH` — the checkout that gets bind-mounted into the container. See the
  warning under [Deploying](#deploying); this is the single most confusing variable
  in the system.
* `ENV_FILE_PATH` — the env file that is mounted at `/usr/lib/.env` and loaded by
  every Perl script through `Dotenv`.
* `VOLUMES_DIR` — host directory holding Grafana, Prometheus, Jenkins and certbot state.
* `CALTECH_CURATION_FILES_*` — the big shared data directory (`/usr/caltech_curation_files`),
  mounted into both `db` and `curation` and served at `/files`.
* `RESTIC_REPO`, `AWS_*_RESTIC`, `RESTIC_PASSWORD` — backup destination and credentials.
* `OKTA_*`, `COGNITO_*`, `AGR_ABC_API_*` — credentials and endpoint for the Alliance ABC API.
* `EMAIL_*` — AWS SES, see [Email](#email-aws-ses).
* `SSH_*` — passwords for the `acedb` and `citace` accounts inside the container.

Perl scripts do not read the environment directly from Compose; they load
`/usr/lib/.env` via `Dotenv`, which **does not overwrite variables already present in
the environment**. That is why you must not add `EMAIL_*` (or similar) to the
`environment:` block of the `curation` service — an empty value there silently
shadows the real one in the env file.

## Running it locally

```bash
docker compose up -d --build        # first time
docker compose up -d                # afterwards
docker compose ps
docker compose logs -f curation
docker compose logs -f db
docker compose down
```

Then:

* public forms → <http://localhost:8080/pub/cgi-bin/index.cgi>
* curator forms → <http://localhost:8080/priv/cgi-bin/> (needs the Basic-auth file at
  `HTTPD_AUTH_FILE_PATH`)
* database → `docker compose exec db psql -U "$PSQL_USERNAME" -d "$PSQL_DATABASE"`
* a shell in the app → `docker compose exec curation bash`

`.env` at the repo root is committed and already points at a local setup; put
machine-specific overrides in `.env.local` (git-ignored) and pass
`--env-file .env.local` on every Compose command.

Because `priv/`, `pub/`, `scripts/` and `user_files/` are bind-mounted, **CGI and
script edits are live on the next request** — no restart. What is *not* live:

| Change | Needed |
| --- | --- |
| a `.cgi` / `.pl` / `.pm` under `website/` or `scripts/` | nothing, next request picks it up |
| `curation/scripts/perl_modules/Jex.pm` | rebuild — it is `COPY`d into the image |
| anything in `curation/website/apache_conf/` | rebuild |
| `curation/crontab` | restart — the crontab is installed at container start |
| `curation/Dockerfile`, installed packages | rebuild |

### AceDB locally (Linux only)

Point `CALTECH_CURATION_FILES_EXTERNAL_PATH` at a local directory and
`CALTECH_CURATION_FILES_INTERNAL_PATH` at its mount point inside the container, then:

```bash
make start-acedb        # runs 'xhost +local:root' and starts the acedb container
```

It needs an X server on the host; the container runs with `network_mode: host`.

### Grafana

Create `grafana/grafana.ini` (git-ignored) with the custom configuration — for
example an `smtp` section so alert notifications can be sent.
`grafana/grafana_original.ini` holds the upstream defaults.

## Deploying

There is **no CI/CD** for this repository. Deployment is a `git pull` plus a Compose
command over SSH. (The Jenkins container on the box builds other projects —
ACKnowledge, WormiCloud, anatomy-function — not this one.)

### The hosts

| | Production | Dev |
| --- | --- | --- |
| DNS | `caltech-curation.textpressolab.com` | `caltech-curation-dev.textpressolab.com` |
| EC2 | `m5.xlarge`, `us-east-1b`, Ubuntu 22.04 | `m5.xlarge`, `us-east-1b`, Ubuntu 22.04 |
| Env file | `/usr/share/caltech-curation-services/env_files/.env.caltech-curation-prod` | `…/.env.caltech-curation-dev` |
| `ENV_STATE` | `prod` (cron runs) | `dev` (no cron) |
| Alliance API | `literature-rest.alliancegenome.org` | `stage-literature-rest.alliancegenome.org` |
| Restic repo | `s3://caltech-curation-services-backup` | `…-backup-dev` |

On both hosts `/usr/share/caltech-curation-services/env_files/.env` is a symlink to
that host's env file, so the same command line works on either machine.

### ⚠ Which checkout is actually served

The Compose *file* is read from whatever directory you run the command in. The
*code that gets served* is whatever `SRC_DIR_PATH` in the env file points at — on
both servers that is **`/home/azurebrd/git/caltech-curation-services`**, which is
readable only by that account.

So:

* To ship a CGI, script or OA change: pull in **`/home/azurebrd/git/caltech-curation-services`**.
  Nothing else is needed — the bind mount means the next request runs the new code.
* Pulling in your own clone and restarting containers deploys **nothing**; it only
  changes which `docker-compose.yml` and `Dockerfile` are used for the build.

### Commands

From a checkout of this repo on the server:

```bash
# rebuild and restart the app (Jex.pm, apache config, Dockerfile changes)
docker compose --env-file /usr/share/caltech-curation-services/env_files/.env \
  up -d --build curation

# restart without rebuilding (e.g. after a crontab change)
docker compose --env-file /usr/share/caltech-curation-services/env_files/.env \
  up -d curation

# the reverse proxy sometimes needs a full recreate to pick up nginx config changes
docker compose --env-file /usr/share/caltech-curation-services/env_files/.env rm -s reverse_proxy
docker compose --env-file /usr/share/caltech-curation-services/env_files/.env up -d --build reverse_proxy
```

Restarting `reverse_proxy` interrupts the other Textpresso services it fronts
(ACKnowledge, WormiCloud, Barista, anatomy-function), so do it deliberately.

### After deploying

```bash
docker compose ps
docker compose logs --tail=100 curation
curl -so /dev/null -w '%{http_code}\n' https://caltech-curation.textpressolab.com/pub/cgi-bin/index.cgi   # expect 200
curl -so /dev/null -w '%{http_code}\n' https://caltech-curation.textpressolab.com/priv/cgi-bin/oa/ontology_annotator.cgi  # expect 401
```

## Operations

### Routing and ports

nginx in `reverse_proxy` owns :80 and :443 on the host and proxies to services on the
Docker bridge address: the curation Apache on `:8080`, Grafana on `:3000`, plus the
unrelated Textpresso apps. Apache then maps `/pub` → `/usr/lib/pub/`, `/priv` →
`/usr/lib/priv/` (Basic auth) and `/files` → the shared curation files directory.
`caltech.wormbase.org` is a separate Apache vhost serving static content, the FTP
`pub/` tree and virtualworm.

TLS certificates are Let's Encrypt, renewed by a certbot cron **inside the
reverse_proxy container** (hourly `certbot renew && nginx -s reload`), with the
certificates on a host volume under `VOLUMES_DIR/certbot`.

### Backups

`restic` runs inside the curation container to S3: daily at 00:00 (30 kept) and
monthly on the 1st at 03:00 (24 kept), covering the shared curation files, the env
file, the Apache password file and the volumes directory. `curation/restic_excludes.txt`
controls what is skipped. Separately, `cronjobs/pgdumps/dump_pg.pl` dumps PostgreSQL
Tue–Sat at 02:00.

### Monitoring

Prometheus scrapes the Postgres exporter and a set of `grok_exporter` instances that
turn log lines from the AFP/VFP/antibody/expression pipelines into metrics;
Alertmanager sends alerts; Grafana serves the dashboards at `/grafana`.

### Logs

```bash
docker compose logs -f curation                  # Apache error log includes Perl warn output
docker compose exec curation tail -f /var/log/restic_daily.log
```

Cron job output goes to `/var/log/` inside the curation container.

### Email (AWS SES)

All outgoing mail — form confirmations, curator notifications, cron job error
reports, the webinar and community curation mailings — goes through `Jex::mailer` in
`curation/scripts/perl_modules/Jex.pm`, which talks to AWS SES over SMTP.

Set these two in the `.env` file that `ENV_FILE_PATH` points at, using the SES SMTP
credentials from the textpresso AWS account:

```
EMAIL_SMTP_USER=<SES smtp username>
EMAIL_PASSWD=<SES smtp password>
```

`EMAIL_SMTP_USER` is an opaque SES credential, not an address, so the visible sender
comes from `EMAIL_FROM` instead. `EMAIL_HOST`, `EMAIL_PORT` and `EMAIL_FROM` are
optional; when empty, `Jex.pm` uses `email-smtp.us-east-1.amazonaws.com`, port 465 and
`WormBase Curation <no-reply@caltech-curation.textpressolab.com>`. `EMAIL_FROM` has to
be an SES-verified identity — `textpressolab.com` is verified as a parent domain, so
any subdomain of it works without further DNS setup.

Because that From is a `no-reply@` address, `mailer` always sets a `Reply-To`, and by
default it is **every address the message went to** — the form submitter plus the
curators in To and Cc — so a submitter hitting reply reaches all the curators on the
thread, which is how these forms have always been read. Leaving the Reply-To off is
not an option: the old From was `outreach@wormbase.org`, a mailbox somebody watches,
so a plain reply used to arrive somewhere. With a no-reply From and no Reply-To it
would go nowhere. Set `EMAIL_REPLY_TO` only to pin every reply to one fixed mailbox
instead; an individual call can also pass its own, as the community curation tracker
and mass mailer do with `curation@wormbase.org`.

`Jex.pm` is copied into the image by `curation/Dockerfile`, it is not bind mounted, so
a change to the mailer needs a rebuild rather than a restart:

```bash
docker compose up -d --build curation
```

To check the credentials, send a test message through the same code path the forms use:

```bash
make test-mailer TO=you@example.org                        # on the server
make test-mailer TO=you@example.org COMPOSE_ARGS='--env-file .env.local'   # on a laptop
```

`make test-mailer` uses `run --rm --no-deps`, so it works whether or not the curation
service is up. The equivalent by hand, and the way to reproduce the shape a form
actually sends — submitter in To, curators in Cc, reply reaching all of them. `-e`,
`-c` and `-r` each take a list: repeat the flag, pass one comma separated value, or
mix the two.

```bash
docker compose run --rm --no-deps \
  curation /usr/lib/scripts/test_mailer.pl \
    -e submitter@example.org \
    -c cgrove@caltech.edu -c garys@caltech.edu -H
```

`test_mailer.pl -h` lists the rest. `TO=` on the make target also accepts a comma
separated list.

To try credentials without editing the env file first, pass them straight in. `Dotenv`
does not overwrite variables that are already in the environment, so these win over
the file:

```bash
docker compose exec -e EMAIL_SMTP_USER -e EMAIL_PASSWD \
  curation /usr/lib/scripts/test_mailer.pl -e you@example.org
```

Do not add the `EMAIL_*` variables to the `curation` service's `environment:` block in
`docker-compose.yml`. Because `Dotenv` yields to whatever is already set, an empty
value there would shadow the real one in the env file.

Every send is logged to the apache or cron log with a `mailer:` prefix, whether it
succeeded or failed, so an outage is visible instead of silent.

## Working on the code

### Conventions

* **Tables**: `pap_*` papers, `two_*` people, `obo_*` ontologies, `gin_*` gene info,
  `cur_*` general curation, `<datatype>_*` per OA datatype. Every data table should
  have a `_hst` twin, and multi-valued fields get their own table.
* **Schema changes** are applied by hand in psql; there is no migration system.
  Remember the history table when you add one.
* **UTF-8 everywhere.** The container's `perl` is a wrapper that adds `-COo`; scientific
  symbols in paper titles will break in interesting ways if you bypass it.
* **CGI scripts are stateless** — one process per request, no shared state, no sessions
  beyond the curator cookie.
* Use `Jex.pm` for headers/footers, form variables, cookies, mail and value filtering
  rather than reimplementing them.
* Perl code follows the house style of the file you are in; this is a 20-year-old
  codebase and styles vary by decade.

### Adding a curation form

1. Add the script under `curation/website/priv/cgi-bin/` (or `pub/cgi-bin/forms/`
   if it is public), executable, `#!/usr/bin/env perl`.
2. Use `Jex.pm` for HTML and database access, and read configuration from `%ENV`
   (populated from `/usr/lib/.env`).
3. Follow the table naming conventions and add the `_hst` history table.
4. If it is an annotation type, prefer configuring a new OA datatype over a new form.

### Testing

There is no automated test suite. Verify changes on the dev host or locally, against
the real forms, before pulling on production.

## Known rough edges

* `.env` is committed to the repository. It is the local-development default, but it
  means the file is a poor place for anything secret — the real ones live on the servers.
* Curator lists and some configuration are hardcoded in several places.
* The `agr_reffile_upload.cgi` permissions model does not fully work for supplemental
  files in subdirectories (noted in the script itself).
* A few CGIs still point at legacy `tazendra.caltech.edu` URLs through
  `PAPER_DISPLAY_CGI_HOST`, `PAPER_EDITOR_CGI_HOST` and `GENERIC_CGI_HOST`.
* The system depends heavily on institutional knowledge; when you work something out,
  put it in this file.

## External resources

* WormBase — <https://wormbase.org>
* Alliance of Genome Resources — <https://www.alliancegenome.org>
* AceDB — <http://www.acedb.org>
