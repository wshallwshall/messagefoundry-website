# messagefoundry-website

Marketing site for **[MessageFoundry](https://github.com/MEFORORG/MessageFoundry)**,
served at **https://messagefoundry.org** via GitHub Pages.

Plain static HTML + CSS — **no build step, no framework, no dependencies.** Edit a file,
commit, push; GitHub Pages publishes it.

## Structure

```
index.html             Home / landing
features.html          Feature detail
getting-started.html   Install + first route
comparison.html        vs Mirth Connect / Corepoint
about.html             What/why, status, license
404.html               Custom not-found (served by Pages)
assets/
  css/styles.css       The whole design system (design tokens via CSS variables)
  js/nav.js            ~20 lines: mobile nav toggle (only JS on the site)
  img/                 favicon.svg, og.svg (social share), logo art
CNAME                  messagefoundry.org  (do not delete — it binds the custom domain)
robots.txt, sitemap.xml
```

The header and footer are duplicated inline in each page (deliberate — keeps the site
build-free). If you change nav links or footer, update every page. Inline SVG gradient
`id`s must stay unique within a page (`bm` in the header, `bmf` in the footer).

## Preview locally

Any static file server works. From the repo root:

```bash
python -m http.server 8080
# open http://localhost:8080
```

Root-absolute links (`/features.html`, `/assets/...`) resolve correctly both under this
server and on the custom domain.

## Deploy

GitHub Pages is configured to **deploy from the `main` branch, `/ (root)`**. Pushing to
`main` publishes within a minute or two:

```bash
git add -A && git commit -m "Update site" && git push
```

## Custom domain (messagefoundry.org)

DNS is hosted at GoDaddy. Apex `@` points at GitHub Pages' four A records; `www` is a
CNAME to `wshallwshall.github.io`. The `CNAME` file in this repo sets the domain on the
GitHub side. Full setup steps live in [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Content accuracy

Follow the owner-approved scope and maturity guidance in [CLAUDE.md](CLAUDE.md).
Describe the approved Early Access capabilities in present tense. State the
project's beta status and link to `status.html` for its limits. Do not infer new
capabilities from older engine documents or add claims without supporting evidence.
