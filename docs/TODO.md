# Website to-do / backlog

Living list of follow-ups for the marketing site. Keep it short; delete items when done.

## Open

- **Revise the About page (`about.html`).** Flagged for a content/copy pass — review and rework
  the messaging (Why it exists / Status / License / Contributing / Get in touch). Keep it aligned
  with the engine repo's built-vs-planned state and the current site positioning.
- **Content freshness — competitor facts.** The comparison page cites KLAS rankings, ownership,
  and licensing that change over time (e.g. KLAS is published yearly). Revisit annually and
  re-verify against the sources listed on `comparison.html`. Source of truth for our own
  built-vs-planned claims is the engine repo's `docs/` (notably `AI.md`, `PHI.md`).
- **Footer "spec" detail.** The footer badge row now reads as benefits (Open source / No
  lock-in / Self-hosted). If a quick spec (Python version, exact license) is wanted somewhere,
  the footer-bottom line already states the AGPL license.
- **⚠ Reconcile the engine repo's public docs with the new security posture.** `security.html` now
  makes strong, standards-led claims (NIST SSDF / 800-115 / 800-53 / 800-66, OWASP ASVS 5.0 L2,
  secure-by-default with TLS + at-rest encryption on, modern interface auth, in-order delivery). The
  page invites a reader to **"read the source."** The engine repo's `docs/SECURITY.md`, `docs/PHI.md`,
  and any CISO-review / architecture docs still describe the **older, gap-laden** posture (e.g. no TLS
  yet, MFA/retention/redaction planned) and the at-least-once delivery semantics — a CISO who follows
  the invitation will find claims that **contradict** the site. Before this batch is pushed, the engine
  repo's docs must be brought in line with the Standards document (or the specific gaps re-disclosed),
  and any live exploit-path detail scrubbed from the now-public repo. **This is the gating concern.**

## Reference docs

- **`docs/COMPETITIVE-POSITIONING.md`** — the canonical positioning doc the comparison page is built
  from (sourced KLAS / ownership / licensing facts, built-vs-planned split). Keep `comparison.html`
  aligned with it; it mirrors the engine repo's `docs/marketing/COMPETITIVE-POSITIONING.md`.

## Secure Development Standards PDF — regeneration

`security.html` links the **Secure Development Standards** PDF
(`assets/MessageFoundry-Secure-Development-Standards.pdf`). Source of truth is the markdown at
`docs/secure-development-standards.md` (mirrored from the engine owner's
`Secure_Development_Standards.md`; the website copy has the status set to **Released**, not "Draft for
review"). Regenerate after edits — render the markdown to a branded HTML page, then print it to PDF:

1. `python` + `markdown` (extensions: `tables`, `fenced_code`, `sane_lists`) wrapped in the branded
   print-CSS template → a temp `docs/_standards-src.html`.
2. Print that to PDF, then delete the temp HTML:

       chrome --headless=new --disable-gpu --no-pdf-header-footer \
         --print-to-pdf="assets/MessageFoundry-Secure-Development-Standards.pdf" \
         "file:///ABSOLUTE/PATH/docs/_standards-src.html"

(The earlier sanitized **posture-summary** PDF and its `docs/security-posture-summary.html` source were
retired when the standards-led page shipped.)

Open: decide whether to promote the security page from the footer into the top nav.

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
- Engine repo is private → added a `source.html` "open source, opening soon" placeholder and
  redirected every GitHub link site-wide to it; softened action labels (Star it / Open an issue /
  Ask a question). Dropped "in Python" from the index `<title>` / OG / Twitter titles.
- Engine repo went **public** under the new `messagefoundry` org → reverted every GitHub link from the
  `/source.html` placeholder to `github.com/messagefoundry/messagefoundry` (nav, footer, CTAs,
  getting-started clone + "Go deeper" doc cards), restored the original action labels, removed
  `source.html`, and updated `README.md`. (Website repo unchanged.)
- Reliability/delivery copy pass: reworded the absolute "never lost" claims to the durability
  mechanism ("durable before ACK" / "durable by design"), and scoped the "Never lose a message" card
  to tracking. **Decision (owner): keep the honest "reliable / durable-by-design" framing** — do not
  claim exactly-once or in-order (the engine's guarantee is at-least-once).
- Added a one-line CI/CD benefit to the home ("Ships through your own CI/CD") and overview
  ("Pipeline-ready") pages, and Open Graph image dimension/type meta tags (1200×630, PNG) to every
  page.
- **Rebuilt `security.html` as a standards-led differentiator page** — built-to-recognized-standards
  (NIST SSDF / 800-115 / 800-53 / 800-66, OWASP ASVS 5.0 L2, with honest "aligned/tested/mapped/
  verified, not certified" wording), secure-by-default controls, modern interface authentication
  (mTLS / OAuth2 client-credentials / SMART-on-FHIR Backend Services / AD gMSA-Kerberos-LDAPS-
  federation), a shared-responsibility split, a HIPAA Security Rule mapping table, secure SDLC /
  supply-chain, and an evidence/attestation section. "Supports a HIPAA-compliant deployment," never
  "HIPAA compliant"/"NIST certified."
- Published the **Secure Development Standards PDF** (`assets/MessageFoundry-Secure-Development-
  Standards.pdf`, from `docs/secure-development-standards.md`, status set to Released) and linked it
  from the security page; **retired** the old sanitized posture-summary PDF + its
  `docs/security-posture-summary.html` source.
- Claimed **in-order delivery** (FIFO per connection/destination) on `features.html` and the home
  reliability card, per the Standards document.
- Light security-as-differentiator touches on the home: a "Built to recognized standards" hero-meta
  item and a standards mention in the "Patient data protected by default" card.
