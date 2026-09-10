# The copy is shorter and the organization name is current

This change covers all 33 website pages and all 20 downloadable PDFs. The organization is **MessageFoundry, LLC**. The product remains MessageFoundry.

## The main pages reach the point sooner

These approximate counts cover main-page prose. They exclude code, diagrams, structured data, navigation, and footers.

| Page | Before | After | Reduction |
|---|---:|---:|---:|
| Home | 1,369 | 662 | 52% |
| About | 777 | 308 | 60% |
| Status | 1,443 | 642 | 56% |
| Overview | 725 | 538 | 26% |
| AI assistance | 1,193 | 751 | 37% |

| Location | Before | After |
|---|---|---|
| Home headline | “Your fast path off legacy interface engines.” | “Connect healthcare systems on your own servers.” |
| Status heading | “What we do to earn trust we haven't had time to earn” | “How we check the code” |
| About | “The reasoning is simple, and human.” | Removed. The text states the goal directly. |
| Overview | “so problems surface before a clinician or a downstream system ever notices” | “The engine serves a browser console with connection status, throughput, and tools to investigate messages.” |
| AI context | “nothing leaves the workstation through the assistant” | “Assistant requests travel separately from the editor to your provider.” |

The homepage has one security section. Repeated sales sections and duplicate FAQ answers are gone. Guides and specialist pages explain tasks, behavior, and limits directly.

The throughput page keeps measurement conditions beside each figure. It no longer suggests that interface rates simply add together. The 16 ms figure is the reciprocal of the reference rate, not a separate latency measurement.

## Existing work is included

Pull request #107 already merged the other worktree's privacy page, SignPath credit, and previous entity rename. Its tree matched `origin/main` before this change.

This change preserves the privacy policy and SignPath attribution. It updates the organization's name in page text, metadata, legal attribution, and PDF colophons. The obsolete nonprofit formation paragraph is gone.

## Technical documents use STE100 as the editing reference

All 20 PDF sources received a prose pass using ASD-STE100 Issue 9. Changes cover instructions, explanations, and table descriptions. Code examples, configuration values, binding requirements, and quoted evidence remain protected.

The source files remain the editable originals. The PDFs use the existing branded renderer. [The technical writing record](TECHNICAL-WRITING.md) defines the approach and exceptions. Some dense technical table explanations remain above STE sentence limits. This pass does not claim full-document STE100 conformance.

## Verification covers content and rendering

- All 33 HTML pages returned HTTP 200 from the local preview.
- Local links and fragment targets resolved.
- HTML containers remained balanced, with no duplicate IDs.
- Structured FAQ answers match visible answers.
- HTML code examples remained unchanged.
- Website pages contain the new organization name.
- All 20 PDFs (259 pages) match the final source and template. Text, link, page-boundary, blank-page, and organization-name checks pass.
- PDF source code blocks and original link targets remain intact.
- `git diff --check` passed.

The homepage, About, and Status received browser checks. A mobile homepage check used a 390-pixel viewport. PDF review uses all-page contact sheets and full-size dense-table samples.

## Existing source conflicts remain outside this copy edit

This pass does not independently verify product behavior, competitor facts, or legal terms. Competitor comparisons retain their June 2026 date.

The PDF review found older security and audit statements that differ from later website summaries. Examples include TLS defaults, DAST history, and CI measurement history. Their dated source evidence remains intact.

The HIPAA penalty source has a Tier 4 amount that differs from its following summary. This change preserves the legal amounts and wording. Existing license interpretations and indemnification terms also remain unchanged.
