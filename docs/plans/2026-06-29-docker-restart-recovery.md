# Docker Restart Recovery Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the development web container wait for Postgres readiness after restart and keep the image-installed Bundler gems available without reinstalling dependencies on each boot.

**Architecture:** Move database readiness handling into the web entrypoint, keep Rails database preparation after readiness is confirmed, and use the image-installed Bundler path directly instead of masking it with a Docker volume. Keep the change scoped to development container boot and Compose configuration.

**Tech Stack:** Docker Compose, shell entrypoint script, Ruby on Rails, Bundler, PostgreSQL

---

### Task 1: Configure Bundler runtime path without masking image gems

**Files:**
- Modify: `Dockerfile.development`
- Modify: `docker-compose.yml`

**Step 1: Update Bundler environment in the development image**

Set a fixed `BUNDLE_PATH` in the image so Bundler resolves gems from the image-installed path consistently.

**Step 2: Mirror that Bundler path in Compose environment**

Set `BUNDLE_PATH` on the web service environment so runtime commands resolve the same gem path.

**Step 3: Remove the gem volume mount**

Do not mount a named volume over `/usr/local/bundle`, because that can hide the image-installed Rails and Bundler executables.

**Step 4: Preserve existing source bind mount**

Leave the application bind mount intact so development edits still reflect into the container.

### Task 2: Make startup wait for Postgres

**Files:**
- Modify: `docker-entrypoint.sh`

**Step 1: Keep stale PID cleanup**

Retain the existing stale Rails PID removal logic.

**Step 2: Add a `pg_isready` wait loop**

Wait on `DB_HOST`, `DB_PORT`, and `POSTGRES_USER` until Postgres reports readiness before any Rails database command runs.

**Step 3: Remove boot-time dependency installs**

Delete `yarn install` and `bundle install` from the runtime entrypoint so restarts do not re-provision dependencies.

**Step 4: Start services after database preparation**

Run `bundle exec rails db:prepare` and then `bundle exec foreman start -f Procfile.dev`.

### Task 3: Verify configuration

**Files:**
- Verify: `docker-entrypoint.sh`
- Verify: `docker-compose.yml`
- Verify: `Dockerfile.development`

**Step 1: Check shell script syntax**

Run `bash -n docker-entrypoint.sh`.

**Step 2: Check Compose rendering**

Run `docker compose config`.

**Step 3: Inspect resulting diff**

Run `git diff -- docker-entrypoint.sh docker-compose.yml Dockerfile.development docs/plans/2026-06-29-docker-restart-recovery-design.md docs/plans/2026-06-29-docker-restart-recovery.md`.
