#!/usr/bin/env bash
#
# Backend deploy for the self-hosted Oracle Cloud VM (Ubuntu 24.04, arm64).
# Replaces the old Render CD. Runs on the VM.
#
# What it does, in order:
#   1. Fast-forwards the checkout to origin/$BRANCH (PUBLISH_V by default).
#   2. Rebuilds the API image on the box (native arm64).
#   3. GATE: checks Prisma migration status. If ANY migration is pending (or the
#      DB is otherwise not in sync), the deploy is CANCELLED and the running API
#      is left untouched. This script never applies migrations — schema changes
#      are a deliberate, separate step. Apply them with `migrate.sh`, then
#      re-run this.
#   4. Takes a safety DB backup (skippable).
#   5. Rolls the API onto the freshly built image and waits for /health.
#
# The DB is never modified here, so a cancelled or failed deploy cannot corrupt
# data — worst case the previously running API keeps serving.
#
# Run it on the VM (SSH in first):
#   bash ~/expensy/scripts/deploy.sh     # from the repo checkout (auto-relocates, see below)
#   bash ~/ops/deploy.sh                 # from the resident ops copy
#
# Self-relocation: because this script does `git reset --hard` on $REPO_DIR, it
# refuses to run from inside that checkout (git could overwrite it mid-run).
# When launched from the repo it copies the ops scripts to ~/ops and re-execs
# from there, which also keeps ~/ops fresh.
#
# Config via env (all optional):
#   REPO_DIR     git checkout to pull        (default: ~/expensy)
#   DEPLOY_DIR   compose project directory   (default: ~/deploy/prod)
#   OPS_DIR      resident copy of the scripts(default: ~/ops)
#   BRANCH       branch to deploy            (default: PUBLISH_V — the release branch)
#   SKIP_BACKUP  set to 1 to skip the pre-deploy safety backup
#
# IMPORTANT: `git reset --hard origin/$BRANCH` discards any uncommitted local
# edits in $REPO_DIR. origin is the source of truth — commit + push first.
#
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/expensy}"
DEPLOY_DIR="${DEPLOY_DIR:-$HOME/deploy/prod}"
OPS_DIR="${OPS_DIR:-$HOME/ops}"
BRANCH="${BRANCH:-PUBLISH_V}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# If we're running from inside the repo checkout that we're about to hard-reset,
# copy the ops scripts out to $OPS_DIR and re-exec from there. This keeps the
# running file safe from `git reset` and refreshes ~/ops in one step.
case "$SCRIPT_DIR/" in
  "$REPO_DIR"/*)
    mkdir -p "$OPS_DIR"
    cp "$SCRIPT_DIR"/*.sh "$OPS_DIR"/
    log "Relocated ops scripts to $OPS_DIR — re-running from there"
    exec bash "$OPS_DIR/$(basename "$0")" "$@"
    ;;
esac

command -v docker >/dev/null 2>&1 || die "docker not found on PATH"
[ -d "$REPO_DIR/.git" ]                 || die "no git repo at $REPO_DIR"
[ -f "$DEPLOY_DIR/docker-compose.yml" ] || die "no docker-compose.yml in $DEPLOY_DIR"

# 1. Pull latest code, matching origin exactly.
log "Updating $REPO_DIR to origin/$BRANCH"
git -C "$REPO_DIR" fetch --prune origin
git -C "$REPO_DIR" checkout "$BRANCH"
git -C "$REPO_DIR" reset --hard "origin/$BRANCH"
echo "Now at $(git -C "$REPO_DIR" rev-parse --short HEAD): $(git -C "$REPO_DIR" log -1 --pretty=%s)"

cd "$DEPLOY_DIR"

# 2. Build the API image (native arm64, on the box). The new migration files are
#    baked into this image, so the status check below sees exactly what would ship.
log "Building API image"
docker compose build api

# 3. Migration gate. `prisma migrate status` exits 0 only when the DB is fully in
#    sync with the migrations in the new image; it exits non-zero if migrations
#    are pending, a migration failed, or the DB is unreachable. Any of those means
#    it is not safe to ship this code, so we CANCEL without touching the API.
log "Checking migration status"
status_out=""
if status_out="$(docker compose run --rm api npx prisma migrate status 2>&1)"; then
  echo "$status_out"
  log "Database schema is in sync — proceeding"
else
  echo "$status_out"
  die "Pending migrations (or DB not in sync) — deploy CANCELLED. The running API
     was NOT changed. Apply migrations deliberately first:
         bash ~/ops/migrate.sh
     then re-run this deploy."
fi

# 4. Safety backup before rolling. The DB is untouched by this deploy, but a fresh
#    restore point right before each ship is cheap insurance.
if [ "${SKIP_BACKUP:-0}" = "1" ]; then
  log "Skipping pre-deploy backup (SKIP_BACKUP=1)"
else
  log "Safety DB backup before rolling the API"
  bash "$SCRIPT_DIR/backup.sh" || die "backup failed — aborting before restart"
fi

# 5. Roll the API onto the freshly built image.
log "Restarting API"
docker compose up -d api

# 6. Health gate. /health is 200 only when the DB is reachable. The db (alpine)
#    container ships busybox wget and can reach the api service by name.
log "Waiting for API /health"
ok=0
for i in $(seq 1 40); do
  if docker compose exec -T db wget -q -O /dev/null "http://api:3000/health"; then
    ok=1; echo "healthy after ${i} check(s)"; break
  fi
  sleep 3
done
[ "$ok" = "1" ] || { docker compose logs --tail=40 api; die "API did not become healthy in ~2 min"; }

log "Deploy complete"
docker compose ps
