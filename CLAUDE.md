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

## Parallel sessions

Several Claude sessions usually work this repo at once, in sibling worktrees under
`.claude/worktrees/`. Two things enforce coordination, and they cover different halves:

- **Hooks (deterministic).** A `SessionStart` banner lists who is live and what files they are
  changing; a `PreToolUse` gate **denies** an edit to a file another live session is already
  changing; a `UserPromptSubmit` hook tells a new session to announce itself. All three are wired at
  user level and resolve `scripts/worktree/session-context.ps1`, `scripts/hooks/collision_gate.ps1`
  and `scripts/hooks/announce.ps1` from this repo — **those paths are load-bearing; renaming one
  silently disables that piece.** The gate fails open on any error.
- **`ccd_session_mgmt` (yours).** Hooks are shell commands and **cannot call MCP tools**, so
  anything needing a peer's *conversation* — reading it, or writing to it — is on you.

**Announce yourself on your first substantive prompt.** The rest of the system is pull-based: you
discover your peers, but they do not discover you until one of them trips the gate, which is after
someone has already built the wrong thing. So when the hook says there are peers, `send_message` each
one **in this repo only** — your worktree, your branch, one line on what you were asked to do — then
get on with it. Don't wait for replies. Skip it only when the prompt is trivial and you won't be
changing files.

**When the gate blocks you, do not just retry or route around it.** Find the peer, `list_events` to
read what it actually concluded — it may already be doing what you were about to start — then either
`send_message` to hand off, pick different work, or ask the user to arbitrate.

- **Match peers by `cwd`, never by the session id you were shown.** The registry id in the banner and
  the `ccd_session_mgmt` id for the *same* session are different UUIDs — verified 2026-07-30 on two
  independent pairs (registry `933195b8-…` = MCP `local_938641cd-…`; registry `63c779cf-…` = MCP
  `local_56f7852e-…`). The first pair both begin `93`, so a matching prefix proves nothing. Call
  `list_sessions` and match on the worktree path.
  - **Refuse to pass an id without the `local_` prefix** to `send_message` or `list_events`. A
    registry UUID is well-formed but wrong, so the call fails *quietly* — and a silent failure reads
    as "the peer ignored me", which is the one conclusion that makes you stop coordinating.
- **`list_sessions` is incomplete — the banner is the authoritative roster.** It enumerates only
  desktop-spawned sessions; a VS Code session in this repo is absent from it entirely (verified
  2026-07-30: 4 listed vs 6 in the on-disk registry). Never conclude "nobody else is here" from it.
  A peer in the banner with no matching `cwd` in `list_sessions` is on such a surface: it cannot be
  messaged, so coordinate via the PR or the user, and say that's what you did.
- **`send_message` lands as a user turn** in the other session, so it interrupts a person's work.
  Use it to hand off context or flag a collision, not to orchestrate background jobs.
- **Never call `archive_session` speculatively** — only when the user has asked to archive that
  specific session.
- **Never edit files in a sibling worktree**, and keep all changes on this worktree's branch.
- **The AI memory directory is shared across every session** (last write wins). Read freely; only
  write when the user has said this session owns memory updates.
- Watch the shared surfaces — `assets/css/styles.css`, `sitemap.xml`, this file, and the header and
  footer duplicated into every page. Site-wide sweeps are where parallel sessions collide.

Roster and overlap on demand:

```bash
pwsh -NoProfile -File scripts/coord/sessions.ps1
```

## Preview & deploy

```bash
python -m http.server 8080        # preview at http://localhost:8080
git add -A && git commit -m "…" && git push   # publishes via Pages from main /(root)
```

Deployment + DNS details: [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Don't

- Don't add a bundler, SSG, Tailwind, or npm — this site is intentionally dependency-free. That rule
  is about what the site **loads**; `scripts/` is local dev tooling, adds no dependency or build step,
  and is not a violation of it. Don't prune it as one.
- **Assume every file in this repo is public.** Pages serves the whole root, so `README.md`,
  `CLAUDE.md`, `docs/` and `scripts/` all answer at `messagefoundry.org/…` (verified `200`). Don't put
  anything in this repo you wouldn't publish.
- Don't hardcode colors; use the CSS variables.
- Don't copy PHI or real message data into examples — sample HL7 is synthetic only.
