# Website to-do / backlog

Living list of follow-ups for the marketing site. Keep it short; delete items when done.

## Open

- **Optional: Open Graph image dimensions.** For slightly faster/cleaner social previews,
  add `og:image:width` (1200), `og:image:height` (630), and `og:image:type` (`image/png`)
  meta tags alongside the existing `og:image` on each page. Not required — the PNG renders
  fine without them.
- **Content freshness — competitor facts.** The comparison page cites KLAS rankings, ownership,
  and licensing that change over time (e.g. KLAS is published yearly). Revisit annually and
  re-verify against the sources listed on `comparison.html`. Source of truth for our own
  built-vs-planned claims is the engine repo's `docs/` (notably `AI.md`, `PHI.md`).
- **Footer "spec" detail.** The footer badge row now reads as benefits (Open source / No
  lock-in / Self-hosted). If a quick spec (Python version, exact license) is wanted somewhere,
  the footer-bottom line already states the AGPL license.

## Copy accuracy review (requested Jun 2026)

Owner flagged copy that may overclaim or read wrong for healthcare buyers. Review and reword —
verify against the engine's docs before changing any technical claim.

- **"At-least-once delivery" framing.** Appears on home, features, comparison, ai, and product
  ("messages are delivered at least once" / "at-least-once delivery"). For healthcare this reads
  wrong — interfaces should deliver **once, in order, no duplicates**. Caveat: at-least-once is the
  engine's *actual* documented outbox guarantee, so reconcile carefully — reword to stress reliable,
  ordered, no-message-lost delivery without overclaiming exactly-once if the engine doesn't guarantee
  it. Check `docs/ARCHITECTURE.md` (store-as-queue) and any de-dup/ordering behavior first.
- **"Setup wizards write the Python for you."** On the home "Why MessageFoundry" lead, and the
  similar "wizards generate the config for you" on features, ai, and product. Owner flags this as
  overstated — verify what the New Connection / New Route wizards actually produce (a scaffold vs
  complete working code) against the engine's `ide/` docs, and soften the copy to match.
- **Awkward heading wrap.** The home "Why MessageFoundry" h2 ("Approachable for your whole team,
  powerful when you need it") orphans "it" onto its own line. Apply `text-wrap: balance` to the
  section h2 (already on `.hero h1`) or shorten the heading.

- **Redo the "A balanced read" callout** on `comparison.html` (the market-shift / "Why now"
  section) — owner finds it clunky. Tighten the wording while keeping the fair point: consolidation
  and the Mirth relicensing reduced the open / low-cost options, but the market isn't closed, and the
  takeaway is that a modern, open alternative fits the moment.

- **Reword the home "Why switch" h2** ("Off legacy — without the legacy price tag") — make it about
  ditching legacy **prices *and* lock-in**, not just price.

## Remove the "code-first" framing (site-wide)

"Code-first" is internal language that scares non-developers. Re-evaluate the whole site and replace
it with framing that appeals to **both analysts and programmers** — easy to use day to day, with the
depth and power of real code there when a case needs it. Keep the underlying truth (it *is* Python you
can read and version-control), but lead with the benefit, not the word "code".

- **Do NOT use** the phrasing "easy when you want it, but powerful when you need it" — it reads as
  innuendo. Also revisit the home "Why MessageFoundry" h2 ("Approachable for your whole team, powerful
  when you need it"), which echoes that construction.
- Reword **features.html h1** specifically: "Open, code-first HL7 — with the tooling to match".
- "code-first" / "code-first Python" / "code-first routing" currently appears in:
  - The **footer brand blurb on every page** — "Open-source, code-first HL7 v2 integration engine for
    healthcare IT." (index, features, comparison, ai, getting-started, about, product).
  - **features.html** — h1, hero lead, the "open source, no lock-in" section lead, and the meta + OG
    `description` tags.
  - **comparison.html** — the intro paragraph, the matrix "MessageFoundry / code-first" column label
    and the "Language / model" row, the Rhapsody and Corepoint head-to-head "MessageFoundry advantage"
    text, and the footer.
  - **index.html** — the meta `description`, OG, and Twitter descriptions, plus the footer.
  - **about.html** — the Status paragraph and the footer.

## Add CI/CD content to the site

The positioning doc now covers modern CI/CD (a matrix row + a "Native CI/CD" *Available now* bullet in
`docs/COMPETITIVE-POSITIONING.md`). Surface it on the live pages:

- **comparison.html** — add the **CI/CD row** to the differentiator matrix (MessageFoundry: *native —
  git PRs, pipeline gate, headless tests*; competitors: export-based / GUI / vendor-driven), and add a
  CI/CD point to the Mirth head-to-head "MessageFoundry advantage".
- **features.html** — add a **CI/CD section**: interfaces as code in git (PR review), the
  `messagefoundry check` commit/CI gate (validate + dry-run, non-zero exit on a bad route), the
  headless scenario runner (`python -m harness --scenario …`, exit 0/1) for CI, and Stage → Promote
  between environments.
- Consider a one-line benefit on the **home** and **product** pages (e.g. "ships through your own
  CI/CD pipeline").
- **Benefit framing** (all grounded in built features): a bad route **fails the build, not a live
  patient feed**; auditable, reviewed change control (the compliance story); no config drift; uses the
  CI/CD pipelines you already run. Credibility: the engine itself ships via GitHub Actions running
  `messagefoundry check`.

## Reference docs

- **`docs/COMPETITIVE-POSITIONING.md`** — the canonical positioning doc the comparison page is built
  from (sourced KLAS / ownership / licensing facts, built-vs-planned split). Keep `comparison.html`
  aligned with it; it mirrors the engine repo's `docs/marketing/COMPETITIVE-POSITIONING.md`.

## New page — the product, shown by component (user-benefit view)

Create a page that introduces MessageFoundry's pieces from a **customer-benefit** angle — what
each does *for the user*, not how it's built. Cover the four components:

- **Monitoring console** — watch message flow live, search and inspect messages, and replay with
  a click; know your interfaces are healthy at a glance.
- **Configuration in VS Code** — a custom extension with **setup wizards** that write the config
  for you, plus full Python power when you need it; author, validate, and promote interfaces
  without leaving your editor.
- **A fast engine that runs as a service** — reliable and headless, runs as a background service
  where your data lives.
- **A complete testing harness** — prove interfaces work against synthetic data before go-live,
  both interactively and in CI.

Keep it benefit-first; the accurate technical specifics already live on the features page.

## New page — security & PHI review (summary + PDF)

Add a security review page positioned as a **trust** page: a concise summary of why
MessageFoundry is a strong, secure choice for **PHI**, with a link to a **full PDF** (still to
be developed).

- **Page = summary.** Lead with the security/PHI story at a benefit level: encryption at rest
  (AES-256-GCM), authentication (local / Active Directory / Kerberos), deny-by-default RBAC with
  per-channel scoping, a tamper-evident hash-chained audit log, a localhost-bound API by default,
  PHI-safe (code-only) AI assistance, and nothing-silently-dropped delivery. Note the
  open-source / source-available transparency angle too.
- **PDF = details.** Link to a downloadable full security review PDF (to come). The PDF is to be
  produced from the engine's **CISO / security markdown doc** (engine repo `docs/security/`).
  The page can ship first with a placeholder link until the PDF exists.
- Wire the new page into the header nav, footer, and sitemap when built. Keep every claim aligned
  with the engine's actual `docs/SECURITY.md` / `docs/PHI.md` (built vs planned).

## Generated assets — how to regenerate

- **`assets/img/og.png`** is the social-share card, **rasterized from `assets/img/og.svg`**
  (browsers don't reliably render SVG Open Graph images, so the tags point at the PNG).
  It does **not** regenerate automatically — if you edit `og.svg`, re-export the PNG at
  1200×630 with headless Chrome/Edge:

  ```bash
  chrome --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --window-size=1200,630 \
    --screenshot="assets/img/og.png" "file:///ABSOLUTE/PATH/assets/img/og.svg"
  ```

  Keep `og.svg` and `og.png` copy in sync, and in sync with the live site's positioning.

- **Brand anvil glyph** lives in `assets/img/logo.svg`, `assets/img/favicon.svg`, and
  `assets/img/og.svg`. If the mark changes, update all three and re-export `og.png`.

## Recently done (Jun 2026)

- Added the AI-assistance / legacy-migration page (`ai.html`).
- Rebuilt the comparison page: 6-engine matrix + interactive competitor selector; corrected
  KLAS attribution (Corepoint #1; Rhapsody #2).
- Reframed home + features around benefits (free/open-source, fast deploy, legacy migration).
- Fixed the 404 page's missing mobile-nav toggle; removed unused `.kicker` CSS.
- Switched the OG image from SVG to a rasterized PNG and refreshed its copy.
- Retargeted the home hero at interface managers escaping costly legacy engines; fixed the
  mobile headline wrap.
- Reframed the home page around customer benefits: dropped the at-least-once callout and the
  architecture/"graph" section (replaced with a "Why switch" cost-and-migration section),
  rewrote the "Why MessageFoundry" card bodies, and updated the closing CTA.
