RUN_DIR = .run
PSQL   ?= /opt/homebrew/Cellar/postgresql@16/16.12/bin/psql
NIX     = nix develop --command
# cab's database lives in no app of this umbrella: name both repos
REPOS   = -r Cab.Repo -r Uadebate.Repo

.PHONY: setup dev build test test-all test-e2e test-phone lint fmt clean up down restart fresh backfill logs status sync-cab release image

# ---------------------------------------------------------------
# Standard targets
# ---------------------------------------------------------------

# The cab submodule (and its engine), the engine's packages, Elixir
# deps, databases
setup:
	git submodule update --init --recursive
	cd cab/engine && npm install
	$(NIX) sh -c 'mix deps.get && cd apps/uadebate && mix ecto.create $(REPOS) && mix ecto.migrate $(REPOS)'

dev: up

build:
	$(NIX) mix compile --warnings-as-errors

# dfu's and uadebate's tests; cab's own run in opendebate-cab
test:
	$(NIX) sh -c 'MIX_ENV=test mix test'

# Unit tests, then cab's full session roundtrip against the running stack
test-all: test test-e2e

# per app: from the umbrella root a clean build extracts every reference twice
lint:
	$(NIX) sh -c 'mix format --check-formatted && (cd apps/uadebate && MIX_ENV=test mix gettext.extract --check-up-to-date) && mix hex.audit'

fmt:
	$(NIX) mix format

clean:
	rm -rf _build $(RUN_DIR)

# ---------------------------------------------------------------
# Local dev stack: engine (node, :3100) + cab (phoenix, :4000) and
# uadebate.com (:4001), both endpoints in the one phoenix server
# ---------------------------------------------------------------

# The engine reads cab/engine/.env; without one it starts with these
# development settings and the JWT secret cab uses (ENGINE_JWT_SECRET in
# .env here). Prefix for a shell line that then runs in cab/engine.
ENGINE_SHELL = set -a; [ -f .env ] && . ./.env; set +a; cd cab/engine; \
	[ -f .env ] || export JWT_SECRET="$${ENGINE_JWT_SECRET:-}" PORT=3100 NODE_ENV=development \
		DB_HOST=localhost DB_PORT=5432 DB_USER=postgres DB_PASSWORD=postgres \
		DB_DATABASE=cab_dev DB_TEST=cab_test;

# Start both services in the background. Logs go to .run/*.log.
up:
	@mkdir -p $(RUN_DIR)
	@if lsof -ti :3100 >/dev/null 2>&1; then \
		echo "engine   already running on :3100"; \
	else \
		($(ENGINE_SHELL) nohup node src/app.js >> ../../$(RUN_DIR)/engine.log 2>&1 &) \
		&& echo "engine   starting on :3100  (log: $(RUN_DIR)/engine.log)"; \
	fi
	@if lsof -ti :4000 >/dev/null 2>&1; then \
		echo "cab      already running on :4000"; \
	else \
		(nohup $(NIX) mix phx.server >> $(RUN_DIR)/cab.log 2>&1 &) \
		&& echo "cab      starting on :4000, uadebate.com on :4001  (log: $(RUN_DIR)/cab.log, first boot may take a minute)"; \
	fi
	@printf "waiting for cab and uadebate.com"
	@for i in $$(seq 1 90); do \
		if curl -s -o /dev/null --max-time 2 http://localhost:4000/ 2>/dev/null \
			&& curl -s -o /dev/null --max-time 2 http://localhost:4001/ 2>/dev/null; then \
			echo " ready"; echo "open http://localhost:4000/ (cab) and http://localhost:4001/ (uadebate.com)"; exit 0; \
		fi; printf "."; sleep 2; \
	done; echo " not up after 3 min - check: make logs"

# Stop the services (kills whatever listens on :3100 / :4000 / :4001).
down:
	@-lsof -ti :4000 2>/dev/null | xargs kill 2>/dev/null; true
	@-lsof -ti :4001 2>/dev/null | xargs kill 2>/dev/null; true
	@-lsof -ti :3100 2>/dev/null | xargs kill 2>/dev/null; true
	@echo "stopped (ports 3100, 4000 and 4001 freed)"

restart: down up

# Wipe the engine's, cab's and uadebate.com's databases, reseed the
# engine, migrate, restart the stack and load fresh demo data around
# your own account:
#   make fresh DEV_USER=<your cab username>
fresh:
	@test -n "$(DEV_USER)" || { echo "usage: make fresh DEV_USER=<your cab username>"; exit 1; }
	@$(MAKE) down
	@echo "== wiping engine db (cab_dev) =="
	$(PSQL) -d postgres -c 'DROP DATABASE IF EXISTS cab_dev;' -c 'CREATE DATABASE cab_dev OWNER postgres;'
	$(ENGINE_SHELL) npx sequelize-cli db:migrate && npx sequelize-cli db:seed:all
	@echo "== wiping cab's and uadebate.com's dbs =="
	$(NIX) sh -c 'cd apps/uadebate && mix ecto.drop --force $(REPOS) && mix ecto.create $(REPOS) && mix ecto.migrate $(REPOS)'
	@$(MAKE) up
	@echo "== loading demo data =="
	set -a; [ -f .env ] && . ./.env; set +a; MIX_ROOT=$(CURDIR) cab/apps/cab/priv/prime_demo.sh $(DEV_USER)
	@echo "fresh demo ready: http://localhost:4000/ and http://localhost:4001/"

# Record lifecycle facts on cab session rows that predate them.
# Safe to re-run; needs the engine up.
backfill:
	$(NIX) mix cab.backfill_sessions

# cab's full session roundtrip (from the submodule, with this project's
# build) against the running local stack (make up). Re-runnable; every
# run makes its own demo club.
test-e2e:
	set -a; [ -f .env ] && . ./.env; set +a; MIX_ROOT=$(CURDIR) cab/apps/cab/priv/walkthrough_rest.sh

# The uadebate.com pages and the cab pages its visitors reach, as an
# iPhone 15 against the running stack (make up): fails when a page
# scrolls sideways. Not part of CI. Signs in as DEV_USER:
#   make test-phone DEV_USER=<a cab username>
test-phone:
	@test -n "$(DEV_USER)" || { echo "usage: make test-phone DEV_USER=<a cab username>"; exit 1; }
	DEV_USER=$(DEV_USER) PATH="$(dir $(PSQL)):$$PATH" uv run tools/phone/phone_check.py

logs:
	@mkdir -p $(RUN_DIR) && touch $(RUN_DIR)/engine.log $(RUN_DIR)/cab.log
	tail -n 40 -f $(RUN_DIR)/engine.log $(RUN_DIR)/cab.log

status:
	@if lsof -ti :3100 >/dev/null 2>&1; then echo "engine   up   :3100"; else echo "engine   down :3100"; fi
	@if lsof -ti :4000 >/dev/null 2>&1; then echo "cab      up   :4000"; else echo "cab      down :4000"; fi
	@if lsof -ti :4001 >/dev/null 2>&1; then echo "uadebate up   :4001"; else echo "uadebate down :4001"; fi

# Move the cab pin to opendebate-cab's latest nightly, with the engine
# pin cab carries (what the nightly workflow does)
sync-cab:
	git -C cab fetch origin nightly
	git -C cab checkout origin/nightly
	git submodule update --init --recursive cab
	git -C cab log --oneline -1

# ---------------------------------------------------------------
# Releases: master moves only here, by fast-forward to nightly
# ---------------------------------------------------------------

IMAGE = ghcr.io/ukrainian-debate-dev-community/uadebate

# make release VERSION=v0.1.0 - from a clean nightly whose CI is green:
# fast-forward master, tag, push both; the tag publishes the image
release:
	@echo "$(VERSION)" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$$' || { echo "usage: make release VERSION=vX.Y.Z"; exit 1; }
	@[ -z "$$(git status --porcelain --untracked-files=no)" ] || { echo "the working tree has changes"; exit 1; }
	@[ "$$(git rev-parse --abbrev-ref HEAD)" = "nightly" ] || { echo "switch to nightly first"; exit 1; }
	@git fetch -q origin
	@[ "$$(git rev-parse HEAD)" = "$$(git rev-parse origin/nightly)" ] || { echo "nightly differs from origin/nightly: pull or push first"; exit 1; }
	@[ -z "$$(git tag -l $(VERSION))" ] && [ -z "$$(git ls-remote --tags origin refs/tags/$(VERSION))" ] || { echo "$(VERSION) already exists"; exit 1; }
	@[ "$$(gh run list --workflow ci.yml --commit $$(git rev-parse HEAD) --json conclusion -q '.[0].conclusion')" = "success" ] || { echo "CI on this commit is not green"; exit 1; }
	@echo "release $(VERSION): master -> $$(git rev-parse --short HEAD) ($$(git log -1 --format=%s)), tag $(VERSION), image $(IMAGE):$(VERSION)"
	@printf "type the version again to confirm: "; read answer < /dev/tty; [ "$$answer" = "$(VERSION)" ] || { echo "cancelled"; exit 1; }
	git push origin nightly:master
	git tag -a $(VERSION) -m $(VERSION)
	git push origin $(VERSION)
	@echo "pushed; the release workflow now builds $(IMAGE):$(VERSION)"

# Build the release image locally (needs docker running)
image:
	docker build -t $(IMAGE):local .
