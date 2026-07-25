#!/usr/bin/env bash
#
# Postgres backup for the self-hosted Oracle VM. You own backups now that the
# DB is off Neon. Produces a custom-format pg_dump (restore with pg_restore)
# and keeps only the newest KEEP_COUNT dumps (default 3).
#
# Run it on the VM (SSH in first):
#   bash ~/expensy/scripts/backup.sh          # from the repo checkout
#   bash ~/ops/expensy/backup.sh               # from the resident ops copy (used by cron)
#
# Nightly cron (03:00 UTC) — runs the resident copy, independent of Windows:
#   mkdir -p "$HOME/ops/expensy" "$HOME/backups/prod"
#   cp "$HOME/expensy/scripts/backup.sh" "$HOME/ops/expensy/backup.sh"
#   chmod 700 "$HOME/ops/expensy/backup.sh"
#   ( crontab -l 2>/dev/null | grep -v 'ops/expensy/backup.sh'; \
#     echo "0 3 * * * bash \$HOME/ops/expensy/backup.sh >> \$HOME/backups/prod/backup.log 2>&1" ) | crontab -
#
# Config via env (all optional):
#   DEPLOY_DIR      compose project dir      (default: ~/deploy/prod)
#   BACKUP_DIR      where dumps are written  (default: ~/backups/prod)
#   KEEP_COUNT      keep this many newest dumps (default: 3)
#
# Restore a dump into the running DB (data + schema into an empty DB):
#   docker compose cp <file>.dump db:/tmp/r.dump
#   docker compose exec -T db pg_restore --clean --if-exists --no-owner \
#     -U expensy -d expensy /tmp/r.dump
#
set -euo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-$HOME/deploy/prod}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/prod}"
KEEP_COUNT="${KEEP_COUNT:-3}"

[ -f "$DEPLOY_DIR/docker-compose.yml" ] || { echo "ERROR: no docker-compose.yml in $DEPLOY_DIR" >&2; exit 1; }
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
cd "$DEPLOY_DIR"

ts="$(date -u +%Y%m%d-%H%M%SZ)"
out="$BACKUP_DIR/expensy-$ts.dump"

echo "[$(date -u +%FT%TZ)] dumping expensy -> $out"
docker compose exec -T db pg_dump -U expensy -Fc expensy > "$out"
chmod 600 "$out"

# Guard against a truncated/empty dump (e.g. the DB was down mid-dump).
if [ ! -s "$out" ]; then
  rm -f "$out"
  echo "ERROR: backup is empty — removed $out" >&2
  exit 1
fi
echo "[$(date -u +%FT%TZ)] wrote $(du -h "$out" | cut -f1) -> $out (mode 600)"

# Retention: keep only the newest KEEP_COUNT dumps; delete the rest.
mapfile -t dumps < <(ls -1t "$BACKUP_DIR"/expensy-*.dump 2>/dev/null || true)
pruned=0
if ((${#dumps[@]} > KEEP_COUNT)); then
  for old in "${dumps[@]:KEEP_COUNT}"; do
    rm -f -- "$old"
    pruned=$((pruned + 1))
  done
fi
echo "[$(date -u +%FT%TZ)] pruned ${pruned} dump(s); keeping up to ${KEEP_COUNT}"
