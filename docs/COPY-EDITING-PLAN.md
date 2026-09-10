# Cut repetition and let the product details build trust

Review date: September 10, 2026.

The site has useful substance, but repeated sales language makes it harder to trust and read. The edit should keep the facts and remove the performance around them.

This plan covers all 33 website pages, shared copy, metadata, and all 20 downloadable PDFs. The user expanded the original website review to include technical documents. Product, competitor, legal, and security claims have not been independently verified.

The organization is **MessageFoundry, LLC**, as confirmed by the owner. The product name remains MessageFoundry. Existing GitHub organization URLs remain unchanged.

Use ASD-STE100 Issue 9 for technical PDF prose. Use its dictionary, consistent technical terms, short instructions, and direct descriptions. Preserve commands, configuration names, numbers, quotations, and binding requirements. Revise explanatory text in tables as well as paragraphs. Regenerate the PDFs from their Markdown sources and inspect the results.

## The same arguments appear too often

The homepage introduces cost, self-hosting, migration, reliability, and security, then sells them again in several sections. The overview, features, toolkit, and specialist pages repeat much of that introduction.

Some repetition helps readers who enter through a search result. Each page needs a short introduction, but it does not need the whole sales pitch.

| Pattern | Example from the site | Editing decision |
|---|---|---|
| Forced contrast | “Migrate with AI, not a project” (`index.html`) | Explain that the assistant drafts code. Keep review, testing, and cutover work visible. |
| Stock positioning | “For PHI, security is the foundation — not a feature.” (`index.html`) | Lead with the controls and their limits. Remove the slogan. |
| Announced sincerity | “The reasoning is simple, and human.” (`about.html`) | Delete it. Let the reason speak for itself. |
| Defensive trust language | “We would rather you hear this from us now than discover it in the middle of a pilot.” (`status.html`) | State the project status directly. |
| Unmeasured superiority | “the highest level, not the easier Level 2” (`status.html`) | Name the assessment level and scope. Remove the swipe at another level. |
| Overpromised outcome | “so problems surface before a clinician or a downstream system ever notices” (`overview.html`) | Describe what the console shows. Do not promise early detection in every case. |
| Inflated benefit | “your costs don't climb every time you add an interface” (`index.html`) | Limit the claim to per-interface license fees. |
| Repeated filler | “modern,” “first-class,” “full power,” “on your terms” | Keep only words that add a specific, supported distinction. |

Long sentences compound the problem. Many combine a feature, its mechanism, several benefits, and a comparison with another product.

Split these by reader need. Describe what happens first, then explain why it matters only when that adds information.

## Keep the details that sound like someone knows the work

Keep concrete examples, field names, commands, message outcomes, and operating steps. The route example and practical guides explain the product better than broad claims do.

Keep direct requests such as “Tell us what's missing, what's confusing, and what broke.” The contact page also gives readers a clear task and useful boundaries.

Retain the founding date, beta status, single-maintainer disclosure, and invitation to test in a sandbox. Shorten the surrounding explanation rather than weakening these facts.

Do not make every sentence equally short. Website prose can use contractions and varied sentence lengths without jokes, invented customer stories, or casual filler. Technical PDFs follow STE100, which excludes contractions.

## Give each page a clear job

| Priority | Pages | Plan |
|---|---|---|
| 1 | `index.html` | Explain the product, show one route, give the main reasons to try it, state beta status, and offer a sandbox start. Combine the repeated security sections. Remove the second general sales pitch and duplicate FAQ answers. |
| 1 | `about.html` | Keep why the project began, who builds it, and why it is open source. Cut the market essay, moral self-description, and repeated feature list. Do not present fewer layoffs or more bedside spending as established results. |
| 1 | `status.html` | Organize around current maturity, evidence, limits, and ways to help. State each disclosure once. Remove repeated introductions to honesty and urgency. |
| 1 | `overview.html` | Explain the engine, console, editor, and test tools in brief. Link to detail pages instead of repeating their pitches. |
| 2 | `features.html`, `features-table.html` | Make the table the quick capability lookup. Keep the longer page for explanations that help readers choose or operate a feature. Remove duplicated slogans and introductions. |
| 2 | `tools.html`, `editor.html`, `console.html` | Lead with tasks: configure, inspect, test, replay, and promote. Put process boundaries and API details after the task description. |
| 2 | `ai.html`, `migrate/index.html`, `migrate/mirth/index.html` | Separate optional coding help from migration steps. Keep drafts, review, parity testing, staged cutover, and rollback. Cut repeated claims that migration is fast or easy. |
| 2 | `security.html`, `self-hosted/index.html`, `reliability.html` | Lead with controls and operating behavior. Keep responsibilities, exceptions, and evidence beside the relevant claim. Link to project status for maturity details. |
| 2 | `comparison.html`, `licensing.html`, `sponsor.html` | Replace advocacy with terms, facts, and specific funding uses. Verify sensitive claims before shortening them. Preserve citations and legal wording. |
| 3 | `throughput/index.html` | Lead with how to size a deployment. Follow with a worked example, measurement table, and limits. Remove repeated arguments about misleading benchmarks. Keep units and test conditions attached to figures. |
| 3 | `getting-started.html`, `pypi.html` | Reach the first action sooner. Keep prerequisites and sandbox guidance. Explain package verification once in the install detail page. |
| 3 | `architecture.html`, `dicom.html`, protocol guides | Preserve the technical content. Trim introductions, repeated ownership claims, and sales language between steps. |
| 3 | `hl7-integration-engine/index.html`, `guides/index.html`, `documents.html` | Use clear descriptions of what readers will learn. Reduce repeated search phrases and broad product introductions. |
| 3 | `contact.html`, `thanks.html`, `404.html` | Make only small edits. Preserve form warnings and useful next links. Replace the error-page joke if it distracts from finding a page. |

As a first-pass budget, aim to cut roughly 30–40% of homepage, about, and status prose. This is an editing target, not a quota.

Avoid a fixed reduction for technical references. Their conditions and examples often earn their length.

## Resolve these claims before polishing them

These are source-level questions, not verified findings about the product.

| Location | Question to resolve |
|---|---|
| `throughput/index.html:330` | The page gives a total budget of about 16 ms, including four to five round trips at roughly 11 ms each. The figures do not reconcile as written. Confirm the intended measurement. |
| Homepage, overview, throughput guide | Short summaries suggest capacity grows with more interfaces. The guide says measured aggregate capacity falls well below a simple sum. Use one consistent account with conditions. |
| `ai.html` | The page says requests go from the editor to a provider, but also says nothing leaves the workstation through the assistant. Define exactly what leaves and where it goes. |
| AI and self-hosting pages | Review absolute claims that no patient data can leave. Distinguish message processing, configured destinations, editor context, and provider requests. Do not assume code can never contain patient data. |
| `licensing.html` | Have the responsible reviewer check claims about “outside parties,” internal modifications, interface scripts, and indemnification before editing. Keep the governing license authoritative. |
| `about.html`, `sponsor.html` | Resolved by the owner: use MessageFoundry, LLC. Remove the obsolete nonprofit formation claim. |
| `comparison.html`, migration pages | Refresh dated competitor facts and sources before publication. Remove broad market claims that the sources do not support. |
| Security and homepage copy | Keep self-assessment distinct from independent review. Preserve open assessment items and deployment responsibilities when shortening. |

The repository also has conflicting editorial guidance. `README.md` uses an older built-versus-planned approach; `CLAUDE.md` records later owner decisions about target scope and project maturity.

Resolve that guidance during the copy pass. Do not infer feature scope from older engine documentation or introduce new feature promises.

## Edit in this order

1. Record facts that must survive: license terms, founding date, beta status, capability scope, defaults, exceptions, measurements, and support limits.
2. Resolve the claim questions above with the responsible source or owner.
3. Outline the homepage around product, example, reasons to try it, maturity, and the next action.
4. Edit the homepage, about, status, and overview as one batch to establish the voice.
5. Edit the specialist pages according to their jobs in the table.
6. Trim guide introductions while preserving commands, technical terms, and operating conditions.
7. Update shared banners, link labels, descriptions, social previews, and structured FAQ data to match the visible copy.
8. Review the rendered pages for long blocks, awkward cards, unclear buttons, and broken links.
9. Revise all PDF sources using STE100, including explanatory table cells.
10. Regenerate all 20 PDFs and inspect text, links, page layout, and organization references.

Shared headers and footers are copied across the HTML files. Apply shared wording consistently across all copies.

Keep the short beta notice across the site. Put the full maturity explanation on `status.html`, with brief context where readers decide whether to try the product.

## The edit is ready when every section earns its place

- The opening says what the product does and who would use it.
- Every section answers a new reader question or supports a decision.
- Headings name a task, behavior, or fact rather than praising the product.
- Technical claims retain their conditions, exceptions, and sources.
- The copy does not announce its own honesty, fairness, or humanity.
- Most sentences carry one idea, with varied lengths and a 25-word ceiling for editable prose.
- Buttons describe the next action and fit the destination.
- Metadata and structured answers agree with the page readers see.

Read each edited page aloud as the final voice check. Cut sentences that sound like a pitch being repeated instead of a person explaining the tool.
