#!/usr/bin/env bash
#
# Postgres backup for the self-hosted Oracle VM. You own backups now that the
# DB is off Neon. Produces a custom-format pg_dump (restore with pg_restore)
# and prunes dumps older than the retention window.
#
# Run it on the VM (SSH in first):
#   bash ~/expensy/scripts/backup.sh     # from the repo checkout
#   bash ~/ops/backup.sh                 # from the resident ops copy (used by cron)
#
# Nightly cron (03:00 UTC) — runs the resident copy in ~/ops, independent of
# Windows. Sync at least once (any ops.ps1 run) so ~/ops/backup.sh exists, then:
#   ( crontab -l 2>/dev/null; \
#     echo "0 3 * * * bash \$HOME/ops/backup.sh >> \$HOME/backups/prod/backup.log 2>&1" ) | crontab -
#
# Config via env (all optional):
#   DEPLOY_DIR      compose project dir      (default: ~/deploy/prod)
#   BACKUP_DIR      where dumps are written  (default: ~/backups/prod)
#   RETENTION_DAYS  keep dumps this many days (default: 14)
#
# Restore a dump into the running DB (data + schema into an empty DB):
#   docker compose cp <file>.dump db:/tmp/r.dump
#   docker compose exec -T db pg_restore --clean --if-exists --no-owner \
#     -U expensy -d expensy /tmp/r.dump
#
set -euo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-$HOME/deploy/prod}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/prod}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

[ -f "$DEPLOY_DIR/docker-compose.yml" ] || { echo "ERROR: no docker-compose.yml in $DEPLOY_DIR" >&2; exit 1; }
mkdir -p "$BACKUP_DIR"
cd "$DEPLOY_DIR"

ts="$(date -u +%Y%m%d-%H%M%SZ)"
out="$BACKUP_DIR/expensy-$ts.dump"

echo "[$(date -u +%FT%TZ)] dumping expensy -> $out"
docker compose exec -T db pg_dump -U expensy -Fc expensy > "$out"

# Guard against a truncated/empty dump (e.g. the DB was down mid-dump).
if [ ! -s "$out" ]; then
  rm -f "$out"
  echo "ERROR: backup is empty — removed $out" >&2
  exit 1
fi
echo "[$(date -u +%FT%TZ)] wrote $(du -h "$out" | cut -f1) -> $out"

# Retention: delete dumps older than RETENTION_DAYS.
pruned="$(find "$BACKUP_DIR" -name 'expensy-*.dump' -mtime +"$RETENTION_DAYS" -print -delete | wc -l | tr -d ' ')"
echo "[$(date -u +%FT%TZ)] pruned ${pruned} dump(s) older than ${RETENTION_DAYS}d"
