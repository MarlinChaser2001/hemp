/**
 * **The Admin API, from a shell** — one place that mints a token and runs GraphQL.
 *
 *   node scripts/admin.mjs                          # what the store looks like
 *   node scripts/admin.mjs '{ shop { name } }'      # any query, as one argument
 *
 * Two ways in, and it accepts either:
 *
 * - **Client credentials grant** (`SHOPIFY_CLIENT_ID` + `SHOPIFY_CLIENT_SECRET`) — the Dev
 *   Dashboard flow. The app swaps its own credentials for a token at
 *   `POST /admin/oauth/access_token` with `grant_type=client_credentials`, which is the point of
 *   the grant: no redirect URL, no browser, nothing to click. The token expires (the response says
 *   when), so it is cached in `.shopify-admin-token` — gitignored — and re-minted when it is close
 *   to expiry.
 * - **A custom app's access token** (`SHOPIFY_ADMIN_ACCESS_TOKEN`, `shpat_…`) — created in the store
 *   admin under Settings → Apps, installed there, and shown once. Used as-is, never cached.
 *
 * The store's own handle is `SHOPIFY_SHOP` — the subdomain only, without `.myshopify.com`, which is
 * the shape the grant's docs ask for.
 *
 * **Why this exists.** A Theme Access password is theme-scoped: it can push a theme and it cannot
 * read a product. Everything catalogue-shaped — importing 161 products, creating 21 collections,
 * assigning products to them, and then *verifying* any of it while the storefront's public JSON is
 * shut behind private mode — needs the Admin API, and this is the smallest thing that gets there.
 *
 * Secrets are read from `.env` (gitignored) and never printed. The token is written to a file with
 * the expiry beside it, so a run never has to ask for the credentials twice in a day.
 */
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { URLSearchParams } from "node:url";

const ENV_FILE = ".env";
const TOKEN_CACHE = ".shopify-admin-token";
const API_VERSION = "2025-10";

// Node 20.12+ can read a dotenv file natively; real environment variables win.
if (existsSync(ENV_FILE)) process.loadEnvFile(ENV_FILE);

const SHOP = (process.env.SHOPIFY_SHOP ?? "").replace(/\.myshopify\.com$/i, "");
const CLIENT_ID = process.env.SHOPIFY_CLIENT_ID ?? "";
const CLIENT_SECRET = process.env.SHOPIFY_CLIENT_SECRET ?? "";
const DIRECT_TOKEN = process.env.SHOPIFY_ADMIN_ACCESS_TOKEN ?? "";

if (!SHOP) {
  console.error("SHOPIFY_SHOP is not set — it is the store handle, without .myshopify.com.");
  process.exit(2);
}

/** Cached token, so a day of runs costs one exchange. */
function readCache() {
  if (!existsSync(TOKEN_CACHE)) return null;
  try {
    const { token, expiresAt } = JSON.parse(readFileSync(TOKEN_CACHE, "utf8"));
    if (!token || !expiresAt || Date.now() > expiresAt - 60_000) return null;
    return token;
  } catch {
    return null;
  }
}

async function mintToken() {
  if (DIRECT_TOKEN) return DIRECT_TOKEN;
  if (!CLIENT_ID || !CLIENT_SECRET) {
    console.error(
      "No credentials. Set SHOPIFY_CLIENT_ID + SHOPIFY_CLIENT_SECRET (Dev Dashboard app) " +
        "or SHOPIFY_ADMIN_ACCESS_TOKEN (custom app token) in .env.",
    );
    process.exit(2);
  }

  const cached = readCache();
  if (cached) return cached;

  const response = await fetch(`https://${SHOP}.myshopify.com/admin/oauth/access_token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "client_credentials",
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
    }),
  });

  // Read the body once: this endpoint answers JSON on success and an HTML page on failure, and a
  // body can only be consumed a single time.
  const text = await response.text().catch(() => "");
  let body = {};
  try {
    body = JSON.parse(text);
  } catch {
    // Not JSON — Shopify's HTML error page. The code is scraped out below.
  }

  if (!response.ok || !body.access_token) {
    /*
     * Shopify answers this endpoint with an HTML page on failure, not JSON, and the useful part is
     * one token in the markup: `Oauth error app_not_installed`. Digging it out is worth it, because
     * "400 Bad Request" sends people to their credentials when the real fault is that nobody
     * clicked Install.
     */
    const code = body.error ?? /Oauth error ([a-z_]+)/i.exec(text)?.[1] ?? String(response.status);
    console.error(`Token request failed: ${code}`);
    if (code === "app_not_installed") {
      console.error(
        `The app is not installed on ${SHOP}. In the Dev Dashboard open the app and install it on ` +
          `this store (a custom-distribution app has an install link); or make a custom app inside ` +
          `the store admin, press Install, and use its shpat token instead (SHOPIFY_ADMIN_ACCESS_TOKEN).`,
      );
    } else if (code === "invalid_client") {
      console.error("The client ID or secret does not match the app — re-copy both from the Dev Dashboard.");
    } else {
      console.error(
        "The grant also needs the app's scopes saved to a version, not just ticked in the editor.",
      );
    }
    process.exit(1);
  }

  writeFileSync(
    TOKEN_CACHE,
    JSON.stringify(
      { token: body.access_token, expiresAt: Date.now() + (body.expires_in ?? 3600) * 1000 },
      null,
      2,
    ),
  );
  return body.access_token;
}

async function graphql(query, variables = {}) {
  const token = await mintToken();
  const response = await fetch(`https://${SHOP}.myshopify.com/admin/api/${API_VERSION}/graphql.json`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "X-Shopify-Access-Token": token },
    body: JSON.stringify({ query, variables }),
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(`GraphQL request failed: ${response.status} ${response.statusText}`);
  if (body.errors?.length) throw new Error(`GraphQL errors: ${JSON.stringify(body.errors)}`);
  return body.data;
}

const QUERY = process.argv[2] ?? `{
  shop { name myshopifyDomain currencyCode }
  productsCount { count }
  collectionsCount { count }
}`;

const data = await graphql(QUERY).catch((err) => {
  console.error(err.message);
  process.exit(1);
});

console.log(JSON.stringify(data, null, 2));
