#!/usr/bin/env bash
#
# Hemp — stop the Podman stack.
#
#   ./scripts/podman-down.sh          stop + remove containers, KEEP the database
#   ./scripts/podman-down.sh --wipe   also delete the database volume (destructive)
#
# The `wordpress/` folder is a bind mount, so your code, uploads and wp-config.php
# are never touched by this — they live on your disk, not in a container.

set -euo pipefail

PODMAN="${PODMAN:-podman}"
WIPE=0
for arg in "$@"; do
  case "$arg" in
    --wipe) WIPE=1 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

echo "==> Removing WordPress container"
"$PODMAN" rm -f hemp-wp >/dev/null 2>&1 || true

echo "==> Removing database container"
"$PODMAN" rm -f hemp-db >/dev/null 2>&1 || true

if [ "$WIPE" = "1" ]; then
  echo "==> Deleting database volume hemp-db (all content is lost)"
  "$PODMAN" volume rm hemp-db >/dev/null 2>&1 || true
  "$PODMAN" network rm hemp >/dev/null 2>&1 || true
  echo "Wiped."
else
  echo "Containers removed. The database volume 'hemp-db' is kept — start again with ./scripts/podman-up.sh"
fi
