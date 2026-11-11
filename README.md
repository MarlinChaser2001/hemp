# Hemp

WordPress + WooCommerce storefront for **Hemp**.

WordPress core is installed in `wordpress/` but **not committed** — only this
project's theme, plugins and config are tracked. That keeps updates of core and
WooCommerce out of git diffs while your own code stays reviewable.

## What is ready

| Piece | State |
|---|---|
| WordPress core 7.1.4 | downloaded into `wordpress/` (gitignored) |
| WooCommerce | installed by `scripts/setup-wp.sh` (not vendored) |
| Theme | `wp-content/themes/hemp` — child of Twenty Twenty-Five, WooCommerce support + brand palette |
| Plugin scaffold | `wp-content/plugins/hemp-core` — home for store-specific logic |
| Local stack | `docker-compose.yml` (MariaDB 11 + WordPress/PHP 8.3 + WP-CLI) |
| Installer | `scripts/setup-wp.sh` — idempotent, creates DB + admin + WooCommerce |

Nothing has been *run* yet: this sandbox has no PHP, MySQL or Docker, so the
installer has to run on your machine (see below).

## Quickstart — Docker (recommended)

```bash
cd ~/Desktop/hemp
cp .env.example .env
# edit .env: DB passwords, WP_ADMIN_PASSWORD, WP_ADMIN_EMAIL, and UID/GID (`id -u`, `id -g`)

docker compose up -d                             # db + wordpress on http://localhost:8080
docker compose --profile setup run --rm wpcli    # installs WP, WooCommerce, activates theme
```

Then open <http://localhost:8080/wp-admin> and sign in with the credentials from
`.env`.

Both commands are safe to re-run — the installer only fills in what is missing.

```bash
docker compose down          # stop (data stays in the db_data volume)
docker compose down -v       # stop and wipe the database
```

## Quickstart — Local by Flywheel / existing PHP + MySQL

1. Create a site with **Local** (or any PHP 8.1+ / MySQL 8 / MariaDB 10.6+ host)
   whose web root is this repo's `wordpress/` folder.
2. Point `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` and `WP_URL` at that site
   (either export them or put them in `.env`).
3. Run the installer from a shell that has WP-CLI and PHP:

```bash
WP_PATH="$PWD/wordpress" DB_HOST=127.0.0.1:3306 ./scripts/setup-wp.sh
```

WP-CLI alone is enough if PHP and MySQL are already running; the script downloads
core only when it is missing (`WP_VERSION=6.8 ./scripts/setup-wp.sh` to pin).

## Layout

```
hemp/
├── docker-compose.yml        local stack
├── .env.example              copy to .env (gitignored)
├── wp-cli.yml                defaults for a local `wp`
├── scripts/setup-wp.sh       installer (Docker or local)
└── wordpress/                ← web root
    ├── wp-admin/ …           core, gitignored
    └── wp-content/
        ├── themes/hemp/      ← tracked
        ├── plugins/hemp-*/   ← tracked (WooCommerce itself is not)
        ├── mu-plugins/       ← tracked, always-on code
        └── uploads/          gitignored
```

Tracked vs ignored is defined in `.gitignore`: third-party themes/plugins,
uploads, `wp-config.php`, `.env` and all of core stay out of the repo.

## Everyday commands

With Docker, prefix WP-CLI with the cli service:

```bash
docker compose run --rm --profile setup --entrypoint wp wpcli plugin list
docker compose run --rm --profile setup --entrypoint wp wpcli plugin install wordfence --activate
docker compose run --rm --profile setup --entrypoint wp wpcli wc product create --name="Hemp oil" --regular_price=29.95 --user=admin
docker compose run --rm --profile setup --entrypoint wp wpcli plugin update --all
```

(Or add `alias wp='docker compose run --rm --profile setup --entrypoint wp wpcli'`.)

Locally, `wp` in the repo root picks up `wp-cli.yml` and just works.

## Notes

- **PHP 8.3** is the container default; WooCommerce is happiest there.
- **Currency** is set to AUD and the timezone to Australia/Brisbane by the
  installer — change both in Settings → General if that is wrong. Country, tax
  and shipping zones are deliberately left to the WooCommerce setup wizard.
- **Store logic** belongs in `wp-content/plugins/hemp-core`; **presentation**
  belongs in the `hemp` theme. Keeping that line clean means a future redesign
  can't break checkout.
- Keep `wordpress/` out of git. To move the site to another machine, copy the
  repo and run the installer, then import the database.
