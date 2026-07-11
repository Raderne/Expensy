#!/usr/bin/env bash
#
# Apply pending Prisma migrations on the self-hosted Oracle Cloud VM. Runs on the VM.
#
# `deploy.sh` intentionally REFUSES to migrate — it cancels when migrations are
# pending. This script is the deliberate, separate step that applies them, so a
# schema change is always an explicit decision (and always backed up first).
#
# Flow:
#   1. Fast-forwards the checkout to origin/$BRANCH (PUBLISH_V by default).
#   2. Rebuilds the API image so the new migration files are present.
#   3. Takes a mandatory safety DB backup (skippable with SKIP_BACKUP=1).
#   4. Shows status, runs `prisma migrate deploy`, shows status again.
#
# It does NOT restart the running API — run `deploy.sh` afterwards to roll the
# matching code onto the migrated schema.
#
# Run it on the VM (SSH in first):
#   bash ~/expensy/scripts/migrate.sh    # from the repo checkout (auto-relocates)
#   bash ~/ops/migrate.sh                # from the resident ops copy
#
# Config via env (all optional):
#   REPO_DIR     git checkout to pull        (default: ~/expensy)
#   DEPLOY_DIR   compose project directory   (default: ~/deploy/prod)
#   OPS_DIR      resident copy of the scripts(default: ~/ops)
#   BRANCH       branch to migrate from      (default: PUBLISH_V)
#   SKIP_BACKUP  set to 1 to skip the pre-migrate safety backup (not recommended)
#
# IMPORTANT: `git reset --hard origin/$BRANCH` discards uncommitted local edits —
# commit + push first.
#
set -euo pipefail

REPO_DIR="${REPO_DIR:-$HOME/expensy}"
DEPLOY_DIR="${DEPLOY_DIR:-$HOME/deploy/prod}"
OPS_DIR="${OPS_DIR:-$HOME/ops}"
BRANCH="${BRANCH:-PUBLISH_V}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

# Same self-relocation as deploy.sh: don't run from inside the checkout we reset.
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

# 2. Build so the throwaway migrate container has the new migration files.
log "Building API image"
docker compose build api

# 3. Mandatory safety backup before any schema change.
if [ "${SKIP_BACKUP:-0}" = "1" ]; then
  log "Skipping pre-migrate backup (SKIP_BACKUP=1) — not recommended"
else
  log "Safety DB backup before migrating"
  bash "$SCRIPT_DIR/backup.sh" || die "backup failed — aborting before migrations"
fi

# 4. Apply. A throwaway container runs the migration; the running API is not
#    touched. Show status before and after for a clear audit trail.
log "Migration status (before)"
docker compose run --rm api npx prisma migrate status || true

log "Applying migrations"
docker compose run --rm api npx prisma migrate deploy

log "Migration status (after)"
docker compose run --rm api npx prisma migrate status

log "Migrations applied. Now ship the matching code:  bash ~/ops/deploy.sh"
