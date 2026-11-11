#!/usr/bin/env bash
#
# Hemp — one-shot WordPress + WooCommerce installer.
#
# Runs in two places:
#   • the `wpcli` container:  docker compose --profile setup run --rm wpcli
#   • any machine that has PHP + WP-CLI + a reachable MySQL:
#       WP_PATH=./wordpress DB_HOST=127.0.0.1:3306 ./scripts/setup-wp.sh
#
# Idempotent: it only does what is still missing, so re-running is safe.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Local runs get their settings from .env (docker runs get them via compose).
if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$ROOT_DIR/.env"
  set +a
fi

# Inside the wpcli container the site is /var/www/html; locally it's ./wordpress.
if [ -z "${WP_PATH:-}" ]; then
  if [ -f /var/www/html/wp-includes/version.php ]; then
    WP_PATH=/var/www/html
  else
    WP_PATH="$ROOT_DIR/wordpress"
  fi
fi

WP_URL="${WP_URL:-http://localhost:${WP_PORT:-8080}}"
DB_HOST="${DB_HOST:-127.0.0.1:3306}"
DB_NAME="${DB_NAME:-hemp}"
DB_USER="${DB_USER:-hemp}"
DB_PASSWORD="${DB_PASSWORD:-hemp}"
WP_TITLE="${WP_TITLE:-Hemp}"
WP_ADMIN_USER="${WP_ADMIN_USER:-admin}"
WP_ADMIN_PASSWORD="${WP_ADMIN_PASSWORD:-admin}"
WP_ADMIN_EMAIL="${WP_ADMIN_EMAIL:-admin@example.com}"

if ! command -v wp >/dev/null 2>&1; then
  echo "error: wp-cli not found on PATH. Use the Docker path instead:" >&2
  echo "  docker compose --profile setup run --rm wpcli" >&2
  exit 1
fi

# wp-cli refuses to run as root unless told to (the container may run as root).
WP=(wp)
if [ "$(id -u)" = "0" ]; then
  WP=(wp --allow-root)
fi

mkdir -p "$WP_PATH"
echo "==> Site path: $WP_PATH"

# ── 1. WordPress core ────────────────────────────────────────────────────────
if [ ! -f "$WP_PATH/wp-includes/version.php" ]; then
  echo "==> Downloading WordPress core"
  "${WP[@]}" core download --path="$WP_PATH" ${WP_VERSION:+--version="$WP_VERSION"}
else
  echo "==> Core present"
fi

# ── 2. wp-config.php ────────────────────────────────────────────────────────
if [ ! -f "$WP_PATH/wp-config.php" ]; then
  echo "==> Writing wp-config.php"
  "${WP[@]}" config create \
    --path="$WP_PATH" \
    --dbname="$DB_NAME" \
    --dbuser="$DB_USER" \
    --dbpass="$DB_PASSWORD" \
    --dbhost="$DB_HOST" \
    --skip-check
else
  echo "==> wp-config.php present"
fi

# ── 3. Database ─────────────────────────────────────────────────────────────
"${WP[@]}" db create --path="$WP_PATH" 2>/dev/null || echo "==> Database already exists"

# ── 4. Install WordPress ────────────────────────────────────────────────────
if ! "${WP[@]}" core is-installed --path="$WP_PATH" 2>/dev/null; then
  echo "==> Installing WordPress at $WP_URL"
  "${WP[@]}" core install \
    --path="$WP_PATH" \
    --url="$WP_URL" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email
else
  echo "==> WordPress already installed"
fi

# ── 5. WooCommerce ──────────────────────────────────────────────────────────
if ! "${WP[@]}" plugin is-installed woocommerce --path="$WP_PATH"; then
  echo "==> Installing WooCommerce"
  "${WP[@]}" plugin install woocommerce --path="$WP_PATH"
fi
"${WP[@]}" plugin activate woocommerce --path="$WP_PATH"

# ── 6. Theme + housekeeping ─────────────────────────────────────────────────
echo "==> Activating the Hemp theme"
"${WP[@]}" theme activate hemp --path="$WP_PATH"

"${WP[@]}" rewrite structure '/%postname%/' --hard --path="$WP_PATH" >/dev/null 2>&1 || true

# Store defaults that are safe to set once (change them any time in Settings).
"${WP[@]}" option update woocommerce_currency AUD --path="$WP_PATH" >/dev/null
"${WP[@]}" option update timezone_string 'Australia/Brisbane' --path="$WP_PATH" >/dev/null
"${WP[@]}" option update blogdescription 'Hemp — premium hemp goods' --path="$WP_PATH" >/dev/null 2>&1 || true

# The demo plugins WordPress ships with are noise on a real shop.
"${WP[@]}" plugin delete akismet hello --path="$WP_PATH" >/dev/null 2>&1 || true

# ── 7. Summary ──────────────────────────────────────────────────────────────
echo
echo "──────────────────────────────────────────────────────────────"
echo " Store:    $WP_URL"
echo " Admin:    $WP_URL/wp-admin  (user: $WP_ADMIN_USER)"
echo " Version:  $("${WP[@]}" core version --path="$WP_PATH")  |  WooCommerce: $("${WP[@]}" plugin get woocommerce --field=version --path="$WP_PATH")"
echo " Next:     Settings → General for country/tax, then run the WooCommerce setup."
echo "──────────────────────────────────────────────────────────────"
