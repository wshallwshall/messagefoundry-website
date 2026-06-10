# MessageFoundry — Competitive Positioning

**A fair, sourced comparison against the leading HL7 integration engines:**
Mirth Connect (NextGen Connect), Infor Cloverleaf, Rhapsody, Corepoint, and InterSystems
Ensemble / HealthShare Health Connect.

> **About this document.** It is written for prospective evaluators and is meant to be *fair*:
> every competitor here is a capable, established product, and we name where each is genuinely
> stronger than MessageFoundry today. Competitor facts are sourced (see [Sources](#sources)) and
> pricing is described as the vendors disclose it (most do not publish prices). Our own capabilities
> are split into **Available now** and **Planned (roadmap)** — we don't market roadmap as shipped.
> Current as of **June 2026**; vendor packaging and pricing change, so verify specifics before a
> purchase decision.

---

## 1. The one-line wedge

**MessageFoundry is the open-source, code-first, *Python* HL7 integration engine — built for teams
that want control, modern tooling, and no vendor lock-in, at the exact moment the incumbents are
moving the other way.**

The commercial engines are consolidating under private equity, closing their source, and steering
buyers toward subscription contracts. MessageFoundry is deliberately the opposite: an AGPL-licensed
engine whose integration logic is plain Python in *your* git repository, authored and operated in
*your* VS Code, running on *standard* databases — with nothing locked inside a vendor's runtime,
language, or contract.

---

## 2. The market shift — why this matters now

Three things happened to the incumbent landscape that change the buying calculus:

**Mirth Connect left open source.** For 15+ years, Mirth Connect was the free, open-source default
for HL7 integration. In 2024–2025 that ended: **v4.5.2 (Sept 2024) was the last open-source (MPL 2.0)
release, and v4.6 (March 2025) moved to a closed-source, paid commercial model** (Enterprise / Gold /
Platinum tiers, pricing not publicly disclosed), with **no further security patches to the
open-source version**.[1][2] The community's response — two independent forks, the **Open Integration
Engine** and **BridgeLink** — is itself the story: a large base of users adopted Mirth *specifically*
because it was open, and now wants that property back.[3]

**The premium engines consolidated under private equity.** Rhapsody and Corepoint — historically
separate products — are now a single company. Hg Capital acquired Rhapsody from Orion Health in 2018;
the group then absorbed Corepoint (2019), NextGate (2022), and CareCom (2022), and rebranded to
**Rhapsody Health Solutions** in 2023.[6][7][8][9] The group's **Corepoint** engine is genuinely **Best-in-KLAS**
for integration engines — ranked #1 in the category for 16 consecutive years as of 2025 — while the
**Rhapsody** engine has consistently rated just behind it (second in 2025),[4][5] but the whole suite sells through **custom, undisclosed
enterprise pricing and multi-year contracts**, with no open-source or free tier.

**The remaining options carry heavy lock-in.** Cloverleaf — owned by Infor, itself acquired by Koch
Industries in 2020[11] — is scripted in **Tcl**, a language with a small and costly talent pool, and
carries enterprise-grade total cost of ownership.[12] InterSystems **Ensemble is legacy**: its
integration-engine role is now **HealthShare Health Connect**, the engine slice of the broader
**IRIS for Health** data platform, and Ensemble maintenance is scheduled to end around **Q1 2027**.[13][14]
That stack ties you to a proprietary language (ObjectScript) *and* a proprietary database (Caché/IRIS).

**A balanced read:** consolidation and the Mirth relicensing have reduced the open, low-cost options —
but the market is not closed. The Mirth forks are active, and several engines still compete across
segments. MessageFoundry's argument is not "the incumbents are bad"; it's that **a modern, open,
Python alternative is exactly what the moment calls for**, and most buyers no longer have one.

---

## 3. Differentiator matrix

| Dimension | MessageFoundry | Mirth (NextGen) | Cloverleaf | Rhapsody | Corepoint | Ensemble\* |
|---|---|---|---|---|---|---|
| License | **AGPL open source** | Commercial since v4.6 (was MPL ≤4.5.2) | Proprietary | Proprietary | Proprietary | Proprietary |
| Cost posture | Free core + optional services | Paid tiers (undisclosed) | Enterprise/custom, high TCO | Premium/custom, multi-yr | Premium/custom | Core-based, expensive |
| Source available | **Yes — fork it** | Closed since 4.6 | No | No | No | No |
| Language / model | **Python, code-first** | Rhino JS / Groovy | **Tcl** | JS + visual | **No-code / low-code** | **ObjectScript** |
| Talent pool | **Python (vast)** | JS (large) | Tcl (scarce) | JS + product-specific | Product-specific | ObjectScript (scarce) |
| Config as code / git | **Plain Python in your repo** | XML-in-DB (exportable) | Proprietary | Proprietary | Proprietary GUI | Classes in IRIS |
| Lock-in | **None (open, standard DBs)** | Moderate | Moderate–high | Moderate–high (contract) | Moderate–high | **High (language + Caché)** |
| Modern tooling | **VS Code, git, CI gate** | Proprietary console | Proprietary IDE | Proprietary | Proprietary GUI | Studio / VS Code ext |
| Native AI assist | **Yes — governed, code-only by default (PHI-safe mode optional, requires an enterprise agreement with an AI vendor)** | No | No | No | "Axon" (new) | No |
| Reliability | Inbox/outbox WAL, no broker | Mature (proven scale) | Mature (proven scale) | Mature (proven scale) | Mature (KLAS-top) | Mature (high perf) |
| Test tooling | **Full harness included** | Separate | Separate | Separate | Separate | Separate |
| Connectors *(our gap)* | MLLP + File (more planned) | **800+** | Decades of adapters | Broad | Broad | Broad |
| Maturity *(our gap)* | New | 15+ yrs | 30+ yrs | Mature | Mature | 30+ yrs |
| Support & consulting | **24×7 support + consulting** | Large community | Enterprise | **KLAS-leading** | **KLAS-leading** | Enterprise |

> \***Ensemble column = InterSystems' *integration engine***: Ensemble (legacy, maintenance ending
> ~Q1 2027) → HealthShare Health Connect (current). It rates the engine slice, **not** the full
> IRIS for Health platform. "Native AI assist" here means AI help **authoring/porting integration
> code** (Corepoint's Axon, MessageFoundry's chat) — *not* IRIS's in-database data-science ML, which
> is a separate platform capability.

---

## 4. Head-to-head

Each comparison follows the same honest shape: *their genuine strength → the shift → our wedge →
where they still win today.*

### vs Mirth Connect (NextGen Connect)
- **Their strength:** the most widely adopted engine of the last decade — 800+ connectors, a huge
  community, deep documentation, and a battle-tested channel architecture on a cross-platform JVM.
- **The shift:** open source ended at v4.5.2; v4.6+ is closed and paid, with no patches to the free
  line.[1][2]
- **Our wedge:** MessageFoundry is open source *by license* (AGPL) — the property Mirth users adopted
  Mirth for, now preserved — but on a modern foundation: **Python** instead of aging Rhino
  JavaScript, integration logic as **plain code in your git repo** instead of XML stored in a
  database, and a real **VS Code** developer experience. (The Mirth forks preserve *old* Mirth;
  MessageFoundry is a fresh, modern architecture.) And because migration is **AI-assisted**, porting
  your existing channels to Python is typically far less work than re-platforming onto another engine.
- **Where Mirth still wins today:** breadth of pre-built connectors, community size, and years of
  production hardening. MessageFoundry is newer and ships fewer transports today.

### vs Infor Cloverleaf
- **Their strength:** 30+ years of enterprise maturity, an extensive library of healthcare adapters,
  and a reputation for reliability at scale in large integrated delivery networks.[12]
- **The shift:** owned by Infor / Koch Industries[11]; scripted in **Tcl**, where hiring is hard and
  consultants are expensive; enterprise-grade TCO.
- **Our wedge:** **Python instead of Tcl** (you can staff a Python team almost anywhere), open source
  instead of enterprise licensing, modern DevOps tooling instead of a dated console, and **no
  lock-in**.
- **Where Cloverleaf still wins today:** very large, legacy-heavy IDNs that need its proven adapters
  and decades of operational track record right now.

### vs Rhapsody
- **Their strength:** a consistently top-ranked integration engine — at or near the top of the KLAS
  Integration Engine category year after year (second in 2025, just behind its Best-in-KLAS sibling
  Corepoint), with strong support and reliability, robust governance features, broad standards coverage
  (HL7, FHIR, X12, and more), and a mature cloud offering.[4][5]
- **The shift:** a private-equity-owned (Hg Capital) suite built through consolidation, sold via
  **custom, undisclosed pricing and multi-year contracts**, with no open-source or free tier.[6][7]
- **Our wedge:** **open source, no contract lock-in, and Python code-first** against a premium
  proprietary platform — your integration logic lives in your repository, not inside a vendor's
  runtime or commercial agreement.
- **Where Rhapsody still wins today:** support quality, enterprise governance, FHIR/EMPI breadth, and
  proven scale. For a large health system that wants a vendor-managed, top-rated platform, Rhapsody is
  a strong choice.

### vs Corepoint
- **Their strength:** consistently top-rated in KLAS for **ease of use and support** — a guided,
  no-code/low-code experience that lets non-programmer integration teams stand up interfaces
  quickly.[5][10]
- **The shift:** now part of the Rhapsody/Hg portfolio; proprietary and Windows-based on-premises;
  premium pricing; a new AI assistant ("Axon") whose track record is still early.[10]
- **Our wedge:** **code-first power with no no-code ceiling**, made approachable by **setup wizards
  and a PHI-safe AI assistant** — so you get Corepoint-style guided authoring *and* the ability to
  express arbitrarily complex logic, on an open platform, with no lock-in.
- **Where Corepoint still wins today:** for a team that wants *pure* no-code and has no developers,
  Corepoint is easier out of the box. MessageFoundry is code-first; wizards and AI lower the barrier,
  but it is still code.

### vs InterSystems Ensemble / HealthShare Health Connect
- **Their strength:** very high performance and scale, and — at the platform level (IRIS for Health) —
  a unified stack combining a database, interoperability, analytics, in-database ML, and HealthShare's
  HIE/EMPI capabilities.[13]
- **The shift:** Ensemble is **legacy** (maintenance ending ~Q1 2027); its successor as an engine is
  **HealthShare Health Connect**, the integration slice of the **IRIS for Health** platform. The stack
  ties you to **ObjectScript** *and* a **proprietary Caché/IRIS database**.[13][14]
- **Our wedge:** if you are an Ensemble customer, you face a migration regardless — so migrate the
  *integration function* to an open, Python, no-lock-in engine on **standard databases**, rather than
  deeper into a proprietary platform. **You shouldn't have to adopt a proprietary data platform and a
  niche language just to move HL7 messages.**
- **Where InterSystems still wins today:** if a buyer genuinely wants one unified platform — DBMS +
  analytics + in-database ML + HIE/EMPI at massive scale — IRIS for Health delivers that. We are a
  focused integration engine and **do not** claim to replace its database, analytics, or HIE products.

---

## 5. What ships today vs the roadmap

We hold ourselves to the same honesty standard we apply to competitors. These are accurate as of
June 2026.

### Available now
- **Open source** — AGPL-3.0-or-later, with a contributor agreement that also enables a commercial /
  dual license.
- **Reliability without a broker** — transactional inbox/outbox on SQLite (WAL): at-least-once
  delivery, retries with backoff, replay, and dead-lettering; each outbound connection drains
  independently (a slow destination never blocks others); **every received message is persisted with
  a disposition before it is acknowledged** — nothing is silently dropped.
- **Python, code-first** — routing and handling are plain Python (`@router` / `@handler`), wiring
  named Connections; no proprietary DSL, no XML-in-a-database.
- **Real VS Code extension** — completion, live HL7-aware validation, a graph view of your
  integration, source-control integration, and config promotion.
- **Setup wizards** — guided "New Connection" and "New Route" flows that generate the Python for you.
- **Speed by design** — two-tier parsing: a fast, tolerant parser on the routing hot path, with
  strict version-aware validation available opt-in per connection.
- **PHI-safe AI coding assistance** — an in-editor assistant governed by a central policy that sends
  **only code, never message bodies**, gated by role-based access control.
- **AI-assisted migration from other engines** — moving to MessageFoundry is AI-assisted *by design*:
  paste your existing Mirth / Cloverleaf / Rhapsody logic into the editor and the assistant helps you
  express it as Python Connections/Routers/Handlers — typically far less effort than re-platforming
  onto another proprietary engine. (Code-only and governed, per the assistant above.)
- **A full test harness** — a send/receive/file/compose/monitor test bench plus a headless scenario
  runner for CI, included with the product.
- **Security foundation** — authentication + role-based access control (deny-by-default, per-channel
  scoping; local, Active Directory/LDAP, and Kerberos); **encryption at rest** (AES-256-GCM) for
  message bodies; a **tamper-evident, hash-chained audit log** with a verification command; binds to
  `127.0.0.1` by default.
- **Operational niceties** — configuration hot-reload and environment promotion, a dead-letter
  bulk-replay view, configurable ACK modes, message-size/segment guards, and a synthetic HL7
  generator for testing.
- **Database flexibility** — a pluggable message store on standard databases: SQLite by default
  (zero-config, embedded), with SQL Server, PostgreSQL, MySQL, and Oracle — no proprietary data
  platform required.
- **24×7 support & consulting** — commercial support and expert HL7 + Python consulting for
  production deployments: migration assistance, custom connectors, and on-call operations.

### Planned (roadmap — not yet available)
- **Additional transports** — TCP, HTTP, and database connections are planned; today the shipped
  transports are **MLLP and File**.
- **De-identification framework**, **MLLP-over-TLS** and outbound destination allow-listing,
  **centralized log redaction**, and **retention/purge enforcement** — all planned.
- **Managed, BAA-backed AI** (for PHI-scoped assistance) — planned; today the assistant is code-only.

---

## 6. Where the incumbents are genuinely stronger (and an honest note on AGPL)

A fair review names the gaps:

- **Connector / adapter breadth** — Mirth's 800+ connectors and Cloverleaf's/Rhapsody's/InterSystems'
  decades of healthcare adapters far exceed our current MLLP + File transports.
- **Proven scale and maturity** — the incumbents have 15–30 years and thousands of production sites.
  MessageFoundry is new.
- **Third-party ecosystem & certifications** — Rhapsody and Corepoint are KLAS-leading on support, and
  large independent consulting ecosystems and formal certifications exist for all five, built over
  decades. (MessageFoundry offers 24×7 support and consulting directly; the independent ecosystem is
  still growing.)
- **No-code for non-developers** — Corepoint's no-code experience is genuinely easier for teams
  without programmers.
- **Platform breadth** — **IRIS for Health's** full data platform (DBMS + analytics + in-database ML +
  FHIR repository) and **HealthShare's** HIE/EMPI, plus Rhapsody's EMPI/semantic capabilities, go well
  beyond what an interface engine does. We do not try to replace them.

**The AGPL nuance, stated plainly:** AGPL-3.0 is a strong copyleft license. It guarantees the freedom
and no-lock-in we lead with — but some enterprises maintain AGPL review policies. For organizations
that need different terms, a **commercial / dual license** is available. We'd rather you know this up
front than discover it in procurement.

---

## Sources

1. NextGen Healthcare — *A new era for Mirth Connect by NextGen Healthcare* — https://www.nextgen.com/blog/industry-news/a-new-era-for-mirth-connect-by-nextgen-healthcare
2. Meditecs — *Mirth Connect license change* — https://www.meditecs.com/kb/mirth-connect-license-change/
3. Saga IT — *Mirth Connect alternatives (2026): OIE, BridgeLink & more* — https://saga-it.com/blog/mirth-connect-alternatives ; Nirmitee — *Mirth Connect alternatives 2026 after the licensing change* — https://nirmitee.io/blog/mirth-connect-alternatives-2026-after-licensing-change/
4. PRNewswire — *Rhapsody Named Top Integration Engine in 2025 Best in KLAS Report* — https://www.prnewswire.com/news-releases/rhapsody-named-top-integration-engine-in-2025-best-in-klas-report-302368313.html
5. KLAS Research — Rhapsody / Corepoint listing — https://klasresearch.com/review/rhapsody-corepoint/1296
6. Bio-IT World — *Global interoperability leader Lyniate rebrands as Rhapsody* (2023) — https://www.bio-itworld.com/pressreleases/2023/04/04/global-interoperability-leader-lyniate-rebrands-as-rhapsody
7. PRNewswire — *Orion Health finalizes investment deal with Hg* (2018) — https://www.prnewswire.com/news-releases/orion-health-finalizes-investment-deal-with-hg-300740993.html
8. BusinessWire — *Lyniate and NextGate announce merger* (2022) — https://www.businesswire.com/news/home/20220315005333/en/Lyniate-and-NextGate-Announce-Merger-Agreement-Advancing-Healthcare-Interoperability-Leadership
9. Rhapsody — *Rhapsody and Corepoint merge to advance interoperability in healthcare* — https://rhapsody.health/blog/rhapsody-and-corepoint-merge-to-advance-interoperability-in-healthcare/
10. Rhapsody — Corepoint Integration Engine — https://rhapsody.health/solutions/corepoint/
11. Infor — *Koch Industries completes Infor acquisition* (2020) — https://www.infor.com/news/koch-industries-completes-infor-acquisition
12. Infor — Cloverleaf product page — https://www.infor.com/products/cloverleaf
13. InterSystems — IRIS for Health product page — https://www.intersystems.com/products/intersystems-iris-for-health/
14. InterSystems — minimum supported version / maintenance policy — https://www.intersystems.com/support/minimum-supported-version/

> *Competitor pricing is described as publicly disclosed by each vendor; most do not publish prices,
> and figures quoted by third parties are estimates. Verify current terms directly with vendors.
> Trademarks belong to their respective owners. This document is MessageFoundry's positioning,
> prepared in good faith from the sources above.*
