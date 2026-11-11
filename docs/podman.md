# Running Hemp with Podman (Fedora Silverblue)

Silverblue ships Podman and has no Docker daemon, so this is the native path.
Everything below is **rootless** — no `sudo` anywhere, and files the containers
create are owned by *you*.

## The five words you need

| Word | What it actually is |
|---|---|
| **Image** | A read-only template. `wordpress:php8.3-apache` = Debian + Apache + PHP 8.3 + a copy of WordPress. `mariadb:11` = the database server. |
| **Container** | An image *running*. Its own writable layer, thrown away when you `rm` it. |
| **Volume** | Storage that outlives a container. The database lives here. |
| **Bind mount** | A folder from your disk mapped into the container — this is your `wordpress/` code. |
| **Network** | A private net where containers reach each other **by name**. `localhost` inside a container means *that container*, not your machine. |

Why two containers: each runs one job. The web container can be deleted and
recreated without touching data, and MariaDB can be upgraded on its own. That
separation is the whole point of containers.

Why rootless: Podman has no background daemon, so nothing runs unless you start
it. Container root maps to your host user, which is why `wp-config.php` written
inside the WP-CLI container is still *yours* on disk.

## Start it

```bash
cd ~/Desktop/hemp
cp .env.example .env     # set DB_PASSWORD, WP_ADMIN_PASSWORD, WP_ADMIN_EMAIL
./scripts/podman-up.sh
./scripts/podman-install.sh
```

Open <http://localhost:8080> — store front. <http://localhost:8080/wp-admin> —
admin (credentials from `.env`).

Both scripts are idempotent: run them again any time, they only fill in gaps.

## Where your stuff lives

| Thing | Location | Survives `podman-down.sh`? |
|---|---|---|
| Code, theme, plugins | `~/Desktop/hemp/wordpress/` (bind mount) | yes — it's your disk |
| Uploads | `wordpress/wp-content/uploads/` | yes |
| Database | Podman volume `hemp-db` (see `podman volume inspect hemp-db`) | yes |
| Container filesystem | internal | no — never put anything there |

## Day-to-day

```bash
podman ps                                  # what's running
podman ps -a                               # including stopped
podman logs -f hemp-wp                     # Apache/PHP errors live here
podman exec -it hemp-wp bash               # shell inside the web container
podman exec hemp-wp ls wp-content/plugins  # one-off command
podman restart hemp-wp                     # after changing wp-config.php
podman inspect hemp-wp --format '{{.State.Status}}'
```

WP-CLI without installing it on the host:

```bash
podman run --rm --network hemp --user 0:0 \
  -v "$PWD/wordpress:/var/www/html:Z" \
  --entrypoint wp docker.io/library/wordpress:cli-php8.3 \
  --allow-root --path=/var/www/html plugin list
```

(That is the same one-shot container `podman-install.sh` uses.)

## Troubleshooting the things that actually bite

**`Error establishing a database connection` / WP starts before MariaDB**
The installer waits for the DB; if you started them by hand, check
`podman logs hemp-db | tail -20`. The DB is reachable from the web container as
`db:3306` (a network alias), never as `localhost`.

**Apache gets Permission denied on `wp-content`**
SELinux. The bind mount must carry `:Z` (present in the scripts). Without it
Fedora labels the files `user_home_t` and Apache is denied. Fix:
`podman run ... -v "$PWD/wordpress:/var/www/html:Z"`.

**Media uploads fail ("could not create directory")**
The upload is written by Apache, which runs as `www-data` (uid 33). The scripts
chown `uploads/` + `upgrade/` at start-up; if you mounted the folder by hand, run:
```bash
podman exec -u 0 hemp-wp chown -R www-data:www-data /var/www/html/wp-content/uploads
```

**Port already in use**
`ss -ltnp | grep 8080` — change `WP_PORT` in `.env` and re-run `podman-up.sh`.

**I want it on my LAN / another device**
The port is published on `127.0.0.1` on purpose. To expose it, change
`-p 127.0.0.1:${WP_PORT}:80` to `-p ${WP_PORT}:80` in `scripts/podman-up.sh`
**and** set `WP_URL` to the LAN address, then update the `siteurl`/`home` options
(`wp option update home ...`) or WordPress will keep redirecting to localhost.
Open the firewall for that port if you go further.

**Undo everything**
`./scripts/podman-down.sh` keeps your database. `--wipe` deletes the volume too.

## Starting it automatically (optional, later)

Podman can run these at login through **Quadlet** — a `.container` file in
`~/.config/containers/systemd/` plus `systemctl --user daemon-reload`. That's the
modern replacement for `podman generate systemd` (deprecated). Worth doing once
the stack is stable; not needed while you're learning.

If you want them back after a reboot **without logging in first**, enable user
lingering once: `loginctl enable-linger "$USER"`. Without it, user services
(and the containers' restart policy) only start when you log in.

## What about `docker compose`?

The repo also has `docker-compose.yml`, which Podman can consume **if** a compose
provider is installed:

```bash
podman compose version        # tells you which provider it would use
```

On Silverblue, `podman-compose` isn't installed by default and layering it with
`rpm-ostree install podman-compose` needs a reboot. Even then, `profiles:` and
`depends_on: condition: service_healthy` are only partially supported, which is
why the three `podman-*.sh` scripts exist — they do the same thing with no extra
packages and are easier to read while you learn.
