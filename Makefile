start-acedb:
	xhost +local:root
	docker-compose up -d --build acedb

# COMPOSE is overridable because the prod host has the compose v2 plugin
# ('docker compose') and older machines have the v1 script ('docker-compose').
# COMPOSE_ARGS is where '--env-file .env.local' goes when running on a laptop,
# whose .env leaves SRC_DIR_PATH and ENV_FILE_PATH empty.
COMPOSE ?= docker compose
COMPOSE_ARGS ?=

# 'run --rm --no-deps' rather than 'exec', so this works whether or not the
# curation service is up, and without starting the db.  The two -e flags pass
# the credentials through from your shell when they are exported, and are inert
# when they are not, in which case the ones in the env file are used.
test-mailer:
	$(COMPOSE) $(COMPOSE_ARGS) run --rm --no-deps -e EMAIL_SMTP_USER -e EMAIL_PASSWD \
	  curation /usr/lib/scripts/test_mailer.pl -e $(TO)
