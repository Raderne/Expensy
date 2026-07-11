#!/usr/bin/env bash
#
# Operational snapshot for the self-hosted Oracle VM. One glance at whether the
# stack is healthy: containers, API health, DB row counts, disk/memory, the TLS
# certificate expiry, and the most recent backups.
#
# Run it on the VM (SSH in first):
#   bash ~/expensy/scripts/status.sh     # from the repo checkout
#   bash ~/ops/status.sh                 # from the resident ops copy
#
# Config via env (all optional):
#   DEPLOY_DIR  compose project dir     (default: ~/deploy/prod)
#   BACKUP_DIR  backup directory        (default: ~/backups/prod)
#   DOMAIN      public API hostname     (default: api.expensy-app.org)
#
# Not `set -e`: every section should run even if a previous one fails.
set -uo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-$HOME/deploy/prod}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/prod}"
DOMAIN="${DOMAIN:-api.expensy-app.org}"

hr() { printf '\n\033[1;36m== %s ==\033[0m\n' "$*"; }

cd "$DEPLOY_DIR" 2>/dev/null || { echo "no $DEPLOY_DIR"; exit 1; }

hr "Containers"
docker compose ps

hr "API /health (internal)"
if docker compose exec -T db wget -q -O - "http://api:3000/health" 2>/dev/null; then
  echo
else
  echo "UNHEALTHY or unreachable"
fi

hr "DB row counts"
docker compose exec -T db psql -U expensy -d expensy -c \
  'SELECT (SELECT count(*) FROM "User") AS users,
          (SELECT count(*) FROM "Transaction") AS transactions,
          (SELECT count(*) FROM "Category") AS categories,
          (SELECT count(*) FROM "Goal") AS goals;' 2>/dev/null \
  || echo "db query failed"

hr "Disk / memory / swap"
df -h / | awk 'NR==1 || /\/$/'
free -h 2>/dev/null | awk 'NR==1 || /Mem|Swap/'

hr "TLS certificate ($DOMAIN)"
echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null \
  | openssl x509 -noout -issuer -enddate 2>/dev/null \
  || echo "could not read certificate for $DOMAIN"

hr "Recent backups ($BACKUP_DIR)"
ls -lh "$BACKUP_DIR"/expensy-*.dump 2>/dev/null | tail -5 || echo "no backups yet"
