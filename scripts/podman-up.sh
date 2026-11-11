#!/usr/bin/env bash
#
# Hemp — start WordPress + MariaDB with rootless Podman (Fedora Silverblue default).
#
#   ./scripts/podman-up.sh        # start both containers (idempotent)
#   ./scripts/podman-install.sh   # first run: install WP + WooCommerce
#   ./scripts/podman-down.sh      # stop/remove containers, keep the database
#
# No sudo. Podman is daemonless: you are the container's root, files it writes
# land owned by you, and nothing starts until you ask it to.

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
DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-hemp-root}"
DB_HOST="${DB_HOST:-db:3306}"
WP_PORT="${WP_PORT:-8080}"
WP_DEBUG="${WP_DEBUG:-1}"

NETWORK=hemp
VOLUME=hemp-db
DB_CONTAINER=hemp-db
WP_CONTAINER=hemp-wp

command -v "$PODMAN" >/dev/null 2>&1 || {
  echo "error: podman not found. On Silverblue it is preinstalled — check 'podman --version'." >&2
  exit 1
}

echo "==> Network + volume"
"$PODMAN" network exists "$NETWORK" >/dev/null 2>&1 || "$PODMAN" network create "$NETWORK" >/dev/null
"$PODMAN" volume exists "$VOLUME" >/dev/null 2>&1 || "$PODMAN" volume create "$VOLUME" >/dev/null

# ── MariaDB ─────────────────────────────────────────────────────────────────
# --network-alias db lets the app use the same DB_HOST (db:3306) as the Compose
# stack, so .env is portable between the two.
if "$PODMAN" container exists "$DB_CONTAINER"; then
  echo "==> Database container exists — starting it"
  "$PODMAN" start "$DB_CONTAINER" >/dev/null
else
  echo "==> Creating database container"
  "$PODMAN" run -d \
    --name "$DB_CONTAINER" \
    --network "$NETWORK" \
    --network-alias db \
    -e MARIADB_DATABASE="$DB_NAME" \
    -e MARIADB_USER="$DB_USER" \
    -e MARIADB_PASSWORD="$DB_PASSWORD" \
    -e MARIADB_ROOT_PASSWORD="$DB_ROOT_PASSWORD" \
    -v "$VOLUME:/var/lib/mysql" \
    --restart=unless-stopped \
    docker.io/library/mariadb:11 >/dev/null
fi

echo "==> Waiting for MariaDB to accept connections"
ready=0
for _ in $(seq 1 60); do
  if "$PODMAN" exec "$DB_CONTAINER" healthcheck.sh --connect --innodb_initialized >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [ "$ready" != "1" ]; then
  echo "error: MariaDB did not become ready. Logs:" >&2
  "$PODMAN" logs --tail 30 "$DB_CONTAINER" >&2 || true
  exit 1
fi

# ── WordPress ───────────────────────────────────────────────────────────────
# The bind mount carries the SELinux label :Z — without it Fedora denies Apache
# access to the files. Only uploads/upgrade are handed to www-data (uid 33);
# theme and plugin files stay owned by you so git and your editor can write them.
WP_ENTRYPOINT='mkdir -p /var/www/html/wp-content/uploads /var/www/html/wp-content/upgrade &&
chown -R www-data:www-data /var/www/html/wp-content/uploads /var/www/html/wp-content/upgrade &&
exec docker-entrypoint.sh apache2-foreground'

if "$PODMAN" container exists "$WP_CONTAINER"; then
  echo "==> WordPress container exists — starting it"
  "$PODMAN" start "$WP_CONTAINER" >/dev/null
else
  echo "==> Creating WordPress container"
  "$PODMAN" run -d \
    --name "$WP_CONTAINER" \
    --network "$NETWORK" \
    -p "127.0.0.1:${WP_PORT}:80" \
    -e WORDPRESS_DB_HOST="$DB_HOST" \
    -e WORDPRESS_DB_NAME="$DB_NAME" \
    -e WORDPRESS_DB_USER="$DB_USER" \
    -e WORDPRESS_DB_PASSWORD="$DB_PASSWORD" \
    -e WORDPRESS_DEBUG="$WP_DEBUG" \
    -v "$ROOT_DIR/wordpress:/var/www/html:Z" \
    --restart=unless-stopped \
    --entrypoint /bin/sh \
    docker.io/library/wordpress:php8.3-apache \
    -c "$WP_ENTRYPOINT" >/dev/null
fi

echo
echo "──────────────────────────────────────────────────────────────"
echo " WordPress: http://localhost:${WP_PORT}"
echo " Next:      ./scripts/podman-install.sh   (first run only)"
echo " Logs:      podman logs -f $WP_CONTAINER"
echo "──────────────────────────────────────────────────────────────"
