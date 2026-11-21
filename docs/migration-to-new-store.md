# Moving this build to a new store

The dev store (`hemp-shack-dev-yxgdumgm`) is a scratch build: it cannot install apps, its private
mode cannot be switched off, and its storefront is intermittently unavailable because it has no
plan. Everything below is what has to happen in the new store, and what already travels for free.

**The theme is not an export job.** It is in git, so it moves with one push. Only *content* — products
and collections — needs importing.

## What travels for free

| Thing | Why |
|---|---|
| Every section, template, snippet, asset | It is in `hemp-custom/` and in git |
| The home page's content and section order | `templates/index.json` is committed |
| Theme settings (colours, page width, radius) | `config/settings_data.json` is committed |
| The film, the stills, the field artwork | Theme assets, all committed |
| The header/footer wiring (`main-menu`) | `sections/header-group.json` is committed |

## What has to be done in the new store

### 1. Push the theme

Add a second environment to `shopify.theme.toml` rather than editing the default one:

```toml
[environments.newstore]
store = "your-new-store.myshopify.com"
path = "./hemp-custom"
```

`path` is ignored in environments on some versions, so the belt-and-braces version passes both:

```bash
# log in to the new store once, in a terminal
pnpm theme:login --store your-new-store.myshopify.com

# then push our theme to it as an unpublished draft
pnpm theme:push -e newstore --unpublished --theme "Hemp custom"
```

Then publish it (themes → Publish), and delete the leftover Horizon if it is still there.

**Auth note:** a Theme Access password is per store, so the one in `.env` is for the *old* store. Either
log in to the new one in a browser, or make a Theme Access password there and pass it:
`SHOPIFY_CLI_THEME_TOKEN=shptka_… pnpm theme:push -e newstore …`.

### 2. Import the products

**Products → Import** → `skincare-commercial/old site/hempshack-import.csv`

- 750 rows: 161 products, 705 variants, 206 image rows
- images are fetched from the old store's `cdn.shopify.com` URLs, so **keep the old store online**
  until the import finishes
- tags already carry `col-…` markers, alt text is filled, the `hemp shack` brand tag is stripped
- prices are AUD; keep the new store in AUD or the numbers are wrong by the exchange rate

Exporting from the current store instead also works (Products → Export, all products, CSV), and the
tags survive — but the clean file is the safer starting point, because it is the one that has been
checked.

### 3. Create the collections — once, in the new store

`collections-setup.md` lists 19, each **automated on one tag condition** (`col-…`). The first nine are
what the home page and the menu point at. Four clicks each: Create collection → title → Automated →
*Product tag equals* the tag.

Do not create these in the old store now that it is being replaced.

### 4. Menus

**Online Store → Navigation.** The header reads the handle `main-menu`, which is Shopify's default
menu in a new store — so filling that menu in is all the header needs:

- Home, Dogs, Cats & Other Pets, Horses, Pet Treats, Terpenes, Best Sellers

The footer needs no menu: it falls back to all products / collections / search / account / privacy
until one is assigned.

### 5. Policies and pages

Products and collections can be exported as CSV; **pages and policies cannot.** The footer links to
the privacy policy only when one exists, so either write the policies in the new store or accept the
link being absent. Anything else under Online Store → Pages is typed again — there is very little.

## What does not travel, and does not need to

Orders, customers, apps and the domain. There are no orders or customers yet, the theme uses no apps,
and the domain is bought or connected in the new store.

## Check it landed

- Storefront home: hero film, ticker, three doors with photographs, the field band, ingredients
- `/collections/all-pets` and friends resolve (they will, once step 3 is done)
- The shelf shows four products with prices and an Add button
- `?preview_theme_id=` not needed — private mode on the new store can be switched off once it is on a
  paid plan
