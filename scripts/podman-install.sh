#!/usr/bin/env bash
#
# Hemp — install WordPress + WooCommerce inside the running Podman stack.
#
#   ./scripts/podman-up.sh        # first (starts db + wordpress)
#   ./scripts/podman-install.sh   # then this (safe to re-run)
#
# Runs the WP-CLI image as root *inside* the container. With rootless Podman,
# container root maps to your host user, so wp-config.php and the plugins it
# installs stay owned by you. (Running it as uid 1000 would map to a sub-uid and
# you would need sudo to edit them.)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PODMAN="${PODMAN:-podman}"

if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$ROOT_DIR/.env"
  set +a
fi

DB_NAME="${DB_NAME:-hemp}"
DB_USER="${DB_USER:-hemp}"
DB_PASSWORD="${DB_PASSWORD:-hemp}"
DB_HOST="${DB_HOST:-db:3306}"
WP_URL="${WP_URL:-http://localhost:${WP_PORT:-8080}}"
WP_TITLE="${WP_TITLE:-Hemp}"
WP_ADMIN_USER="${WP_ADMIN_USER:-admin}"
WP_ADMIN_PASSWORD="${WP_ADMIN_PASSWORD:-admin}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"

if ! "$PODMAN" container exists hemp-db || ! "$PODMAN" container exists hemp-wp; then
  echo "error: the stack isn't running. Start it first: ./scripts/podman-up.sh" >&2
  exit 1
fi

"$PODMAN" run --rm \
  --network hemp \
  --user 0:0 \
  -v "$ROOT_DIR/wordpress:/var/www/html:Z" \
  -v "$ROOT_DIR/scripts:/scripts:ro,Z" \
  -e DB_HOST="$DB_HOST" \
  -e DB_NAME="$DB_NAME" \
  -e DB_USER="$DB_USER" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e WP_URL="$WP_URL" \
  -e WP_TITLE="$WP_TITLE" \
  -e WP_ADMIN_USER="$WP_ADMIN_USER" \
  -e WP_ADMIN_PASSWORD="$WP_ADMIN_PASSWORD" \
  -e WP_ADMIN_EMAIL="$WP_ADMIN_EMAIL" \
  --entrypoint sh \
  docker.io/library/wordpress:cli-php8.3 \
  /scripts/setup-wp.sh
