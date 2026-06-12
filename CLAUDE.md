# messagefoundry-website — Claude Code conventions

This repo is the **marketing website** for MessageFoundry (the HL7 v2 engine, a separate
repo). It is **not** the engine. Served at https://messagefoundry.org via GitHub Pages.

## What this is

- **Plain static HTML + CSS. No build step, no framework, no package manager, no JS
  dependencies.** The only JavaScript is `assets/js/nav.js` (mobile nav toggle).
- One shared stylesheet, `assets/css/styles.css`, with all design tokens as CSS custom
  properties (`:root`). Reuse the tokens; don't introduce a second styling system.
- Header and footer are **duplicated inline in every page** on purpose (keeps it
  build-free). Change one → change all.
- The brand mark is the MessageFoundry **anvil** (sourced from the engine's VS Code
  extension, `ide/media/icon.svg`). It lives once in `assets/img/logo.svg` and is referenced
  via `<img class="brand-mark" src="/assets/img/logo.svg">`; `favicon.svg` and `og.svg` carry
  the same anvil. Update the glyph in those three files, not per page.

## Conventions

- Links are **root-absolute** (`/features.html`, `/assets/...`) so they work under
  `python -m http.server` and on the apex domain alike.
- Every page: `<title>`, `<meta name="description">`, canonical, favicon, and Open
  Graph/Twitter tags. Set the active nav link with `class="active" aria-current="page"`.
- Accessibility: semantic landmarks, alt/aria on meaningful SVGs (`aria-hidden` on
  decorative ones), visible focus styles, good contrast. Don't regress these.
- **Content accuracy is a hard rule.** Describe the engine as **built vs planned** exactly
  as the engine repo's `README.md` / `docs/` state it. Never invent features, metrics, or
  claims. Competitor mentions (Mirth, Corepoint) stay factual, fair, and hedged, with the
  trademark disclaimer in the footer.
  - **Owner override.** The repo owner may direct the site to state a claim from an
    authoritative source they provide (e.g. the Secure Development Standards) even when the
    engine repo's `docs/` haven't caught up yet — by explicitly telling you to *assume it is
    true and in place*. When that happens: write the claim, but (a) still keep the wording
    honest and unembellished (no "certified"/"guaranteed" unless the source says so), (b)
    **flag the gap** so the owner can reconcile the engine repo's docs, and (c) note that the
    owner is the accountable source for the claim. The default remains repo-stated built-vs-
    planned; the override is per-claim and must be explicit, not assumed.
- **Do not delete `CNAME`** — it binds the custom domain on every Pages deploy.

## Preview & deploy

```bash
python -m http.server 8080        # preview at http://localhost:8080
git add -A && git commit -m "…" && git push   # publishes via Pages from main /(root)
```

Deployment + DNS details: [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Don't

- Don't add a bundler, SSG, Tailwind, or npm — this site is intentionally dependency-free.
- Don't hardcode colors; use the CSS variables.
- Don't copy PHI or real message data into examples — sample HL7 is synthetic only.
