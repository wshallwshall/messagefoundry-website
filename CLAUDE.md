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
- **Content accuracy — the site represents the v0.1 target.** The site describes what MessageFoundry
  will do when **v0.1 is complete** (a near-term target, weeks out), written in **present tense** as
  what the product *does* — not what merged this week. Do **not** add "built vs planned" caveats,
  "Available now / planned" splits, or status badges for v0.1-scope capabilities; that framing is
  retired. The engine repo's `README.md` / `docs/` **lag the v0.1 target** (they describe the current
  MVP), so they are **not** the ceiling for what the site may claim — the v0.1 feature set is. Don't
  invent features, metrics, or claims beyond v0.1, and don't describe genuinely post-v0.1 work as
  current. Keep wording honest and unembellished (no "certified" / "guaranteed" / hard metrics without
  an owner-provided source). Competitor mentions (Mirth, Corepoint, etc.) stay factual, fair, and
  hedged, with the trademark disclaimer in the footer.
  - **The owner defines v0.1 scope — ask, don't guess.** The repo owner is the accountable source for
    what's in v0.1; when unsure whether a capability is in scope, ask rather than inferring from the
    lagging engine docs.
  - **Protocol & message-type breadth (standing owner decision — do not re-litigate).** The site
    positions MessageFoundry as a broad *healthcare interface engine* that connects "a wide range of
    protocols and message types" — pre-approved aspirational framing; write it confidently. (Per owner
    2026-06-24, the site leads with **"interface engine"**, not "integration engine"; the latter now
    survives only in competitor/award proper-names — e.g. Corepoint Integration Engine, the KLAS award.) Specific
    capability claims should still match the v0.1 target (don't claim something v0.1 won't do).
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
