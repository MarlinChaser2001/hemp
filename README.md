# Hemp

Shopify storefront for **Hemp**, developed against a real store with the Shopify CLI.

The WordPress + WooCommerce scaffold this repo began as was removed on 2026-11-21 (see
*History* at the foot). What is here now is theme code plus the CLI configuration that makes
`shopify theme …` work from the repo root.

## Requirements

- **Node 22.12+** — the CLI's own minimum (`node -v`)
- **pnpm 11** — `pnpm -v`
- A Shopify store you can sign in to, with either an existing theme to pull or the right to
  create one

## First run

```bash
pnpm install
pnpm theme:login    # browser login — skip it on a machine that uses a Theme Access token
```

Then tell the CLI which store. Either edit `shopify.theme.toml`:

```toml
[environments.default]
store = "your-store.myshopify.com"
```

…or pass it per command: `pnpm theme:list --store your-store.myshopify.com`.

**The theme is already here**, in `hemp-custom/` — Shopify's Skeleton theme, a minimal
starting point with 0 Theme Check offences. Work in it directly:

```bash
pnpm theme:check           # no login needed — Theme Check runs locally
pnpm theme:dev             # needs a store: preview with hot reload
```

`pnpm theme:pull` is only for **replacing** this with what the store already has (it
overwrites local files), and `--live` says so explicitly. Don't run either to "see what
happens".

`theme:dev` uploads to a **development** theme — never the live one — and prints a preview URL
and a shareable link.

## Everyday commands

| Command | What it does |
|---|---|
| `pnpm theme:list` | themes in the store, with ids, and which one is live |
| `pnpm theme:pull` | store → repo |
| `pnpm theme:dev` | live preview with hot reload, on a development theme |
| `pnpm theme:push` | repo → theme (it asks first; `theme:push:unpublished` makes a new one) |
| `pnpm theme:publish` | make a theme the live one |
| `pnpm theme:check` | Theme Check — Liquid and schema errors, best-practice warnings |
| `pnpm theme:open` | preview links for a theme |
| `pnpm theme:info` | which store and theme the CLI thinks this directory is |
| `pnpm theme:package` | zip the theme for a manual upload |
| `pnpm shopify -- --help` | every command the CLI has |

**Why the `theme:` prefix.** `pnpm info`, `pnpm list`, `pnpm publish` and `pnpm logout` are
pnpm's *own* commands, and a bare `pnpm <name>` runs the built-in before it looks at
`package.json`. Prefixing keeps the store commands out of that shadow; `pnpm run` on its own
lists every script, and `pnpm run <script>` always works.

`shopify.theme.toml` ships with a **placeholder store** (`your-store.myshopify.com`), so the
first command fails with *"Please provide a valid environment"* until you put the real domain
in — that is the one line to edit, and it is a deliberate placeholder rather than a guess at
somebody else's store.

Extra arguments are forwarded to the CLI: `pnpm theme:push --unpublished`,
`pnpm theme:check --output json`, `pnpm theme:dev -e staging`.

## Environments

`shopify.theme.toml` holds flags per named environment, with `[environments.default]` applied
when none is named — the point being that a client preview store or a staging theme costs one
flag rather than four:

```bash
pnpm theme:dev -e staging
```

Precedence is **command flag > environment variable > `shopify.theme.toml`**.

## CI

Two secrets, and they are not admin API credentials:

```bash
SHOPIFY_CLI_THEME_TOKEN=shptka_…                  # a Theme Access password
SHOPIFY_FLAG_STORE=your-store.myshopify.com
```

Add `SHOPIFY_FLAG_NO_INPUT=1` so a missing value fails instead of waiting for an answer, and
pass `--allow-live` only if a pipeline is allowed to publish. `.env.example` lists every
variable the CLI reads.

## Layout

```
hemp/
├── hemp-custom/            the theme — Shopify Skeleton v0.1.0 (assets, config, layout,
│                           locales, sections, snippets, templates, blocks)
├── package.json            @shopify/cli, and the commands in the table above
├── shopify.theme.toml      store / theme / path per environment
├── pnpm-workspace.yaml     pnpm settings (esbuild's build script is approved here)
├── .env.example            the CLI's environment variables, documented
├── .clinerules             instructions for an LLM agent working in this repo
└── skincare-commercial/    old-site product scrape + ad media (not part of the theme)
```

Shopify's canonical layout keeps the theme at the repo root; here it is one level down, so
`shopify.theme.toml` carries `path = "./hemp-custom"` and every `theme:*` command finds it
from the root.

## Do not commit

`.env` (holds a Theme Access password when one is used), `.shopify/` (the CLI's session and
development-theme id), `node_modules/` and `*.zip`. All four are gitignored — `pnpm-workspace.yaml`
is not: it carries `allowBuilds: esbuild: true`, and without it `pnpm install` fails.

## History — what the WooCommerce scaffold was

This repo was a WordPress + WooCommerce storefront: core downloaded into `wordpress/`, a
`hemp` child theme of Twenty Twenty-Five, a `hemp-core` plugin, and a Docker/Podman stack with
an idempotent installer. All of it was deleted on **2026-11-21** when the store moved to
Shopify, and all of it is still in git:

```bash
git log --oneline                        # 1013d5b and the two commits after it
git show 1013d5b --stat
git show 1013d5b:wordpress/wp-content/themes/hemp/theme.json
```

The one thing worth carrying forward is the old theme's palette, for the Shopify theme's colour
scheme settings:

| Token | Hex |
|---|---|
| Hemp green | `#4a5d23` |
| Hemp sage | `#8a9a5b` |
| Hemp cream | `#f5f1e6` |
| Hemp charcoal | `#1f2421` |

**Catalogue data.** `skincare-commercial/old site/hempshack-products.csv` (with `images/`) is
the scrape of the old WooCommerce shop — the input for a Shopify product import, not something
the theme reads. The surrounding scripts and media in that folder are the ad/commercial work,
also independent of the storefront.

