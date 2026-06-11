# Website to-do / backlog

Living list of follow-ups for the marketing site. Keep it short; delete items when done.

## Open

- **Content freshness — competitor facts.** The comparison page cites KLAS rankings, ownership,
  and licensing that change over time (e.g. KLAS is published yearly). Revisit annually and
  re-verify against the sources listed on `comparison.html`. Source of truth for our own
  built-vs-planned claims is the engine repo's `docs/` (notably `AI.md`, `PHI.md`).
- **Footer "spec" detail.** The footer badge row now reads as benefits (Open source / No
  lock-in / Self-hosted). If a quick spec (Python version, exact license) is wanted somewhere,
  the footer-bottom line already states the AGPL license.

## Reference docs

- **`docs/COMPETITIVE-POSITIONING.md`** — the canonical positioning doc the comparison page is built
  from (sourced KLAS / ownership / licensing facts, built-vs-planned split). Keep `comparison.html`
  aligned with it; it mirrors the engine repo's `docs/marketing/COMPETITIVE-POSITIONING.md`.

## Security posture summary PDF — regeneration

`security.html` links a **sanitized** posture-summary PDF (`assets/MessageFoundry-Security-Posture-
Summary.pdf`) — built/partial/roadmap, capabilities table, compliance alignment, deployment
requirements — deliberately **without** the engine CISO review's specific exploit paths / residual-risk
register (that full review stays internal; offered "on request"). Regenerate from the source after
edits:

    chrome --headless=new --disable-gpu --no-pdf-header-footer \
      --print-to-pdf="assets/MessageFoundry-Security-Posture-Summary.pdf" \
      "file:///ABSOLUTE/PATH/docs/security-posture-summary.html"

Open: decide whether to promote the security page from the footer into the top nav.

## ⚠ Engine repo is private — public GitHub links + open-source positioning

`gh` confirms `wshallwshall/MessageFoundry` is **PRIVATE**, so for site visitors:

- **Every GitHub link 404s** — the nav "GitHub ↗" button and the footer Project column (every page),
  the footer Docs column (Architecture / Connections / Security / PHI), the getting-started
  `git clone` command, and the "View on GitHub" / "Star it on GitHub" CTAs.
- **The core "open source — read the code, fork it, AGPL" positioning isn't currently deliverable**
  (you can't read or fork a private repo), and the whole site leads with it.

**Decision (owner):** make the repo **public** (fixes every link and makes the positioning true), or
keep it private — in which case the GitHub links need fixing and the open-source / "fork it" / "read
the source" copy needs reconciling (e.g. "source available on request"). Until resolved, the AGPL /
"audit the code, fork it" claims are aspirational.

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
- Copy pass: reworded "at-least-once" → reliable / nothing-lost (see Open question), softened the
  "wizards write the Python" claim, fixed the orphaned heading wrap (`text-wrap: balance`), tightened
  the "A balanced read" callout, reworded the "Why switch" h2 (prices + lock-in), and changed
  "self-host on your own cloud" → "in your own environment".
- Removed the "code-first" framing site-wide (footers, features h1/leads/meta, comparison
  intro/matrix/wedges, index meta/OG/Twitter, about status) — reframed around "analysts and
  developers alike".
- Added modern CI/CD to the positioning **and** the site (comparison matrix row + a features CI/CD
  section).
- Shipped the **Overview** page (`overview.html`) — the four-component product tour — wired into the
  nav, footer, and sitemap on every page, with the copy fixes (wizard claim, at-least-once,
  environment wording) applied. Raised the mobile-nav breakpoint to 980px so a 6th nav item doesn't
  crowd the header.
- Shipped the **Security & PHI** page (`security.html`) — built-and-enforced controls (auth, RBAC,
  revocable sessions, hash-chained audit, at-rest encryption, nothing-dropped), an honest Phase-1
  posture + roadmap (no-TLS-yet; MFA / retention / redaction / de-id planned), and a transparency /
  "read the review" section. Aligned to the engine's **CISO review**, not the simplified marketing
  positioning. Wired into the footer + sitemap + a home contextual link (footer-only, not top nav).
- Aligned the AD/Kerberos auth wording for accuracy (LDAPS; Kerberos experimental).
- Shipped a **sanitized security posture-summary PDF** (`assets/MessageFoundry-Security-Posture-
  Summary.pdf`, generated from `docs/security-posture-summary.html`) and linked it from the security
  page, replacing the now-404 private-repo "full review" links. Deliberately held back the full CISO
  review — it names live exploit paths and the repo is private, so publishing it verbatim would be a
  public attack map.
- Reliability/delivery copy pass: reworded the absolute "never lost" claims to the durability
  mechanism ("durable before ACK" / "durable by design"), and scoped the "Never lose a message" card
  to tracking. **Decision (owner): keep the honest "reliable / durable-by-design" framing** — do not
  claim exactly-once or in-order (the engine's guarantee is at-least-once).
- Added a one-line CI/CD benefit to the home ("Ships through your own CI/CD") and overview
  ("Pipeline-ready") pages, and Open Graph image dimension/type meta tags (1200×630, PNG) to every
  page.
