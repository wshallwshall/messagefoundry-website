# Deploying the site (GitHub Pages + GoDaddy)

The site is plain static files served by **GitHub Pages** from the `main` branch, at the
custom apex domain **messagefoundry.org** (DNS hosted at **GoDaddy**).

## 1. One-time: enable GitHub Pages

1. Push this repo to GitHub (public).
2. **Settings → Pages**.
3. **Build and deployment → Source:** *Deploy from a branch* → Branch **`main`**, folder
   **`/ (root)`** → **Save**.
4. **Custom domain:** enter `messagefoundry.org` → **Save**. (This repo already contains a
   `CNAME` file with that value; GitHub re-confirms it.)
5. Leave **Enforce HTTPS** unchecked until the DNS check passes and the TLS certificate is
   issued (usually minutes; can take up to 24h). Then enable it.

## 2. One-time: GoDaddy DNS

GoDaddy → **My Products → messagefoundry.org → DNS / Manage DNS**.

**Apex (`@`) — four A records** pointing at GitHub Pages:

| Type | Name | Value           |
|------|------|-----------------|
| A    | @    | 185.199.108.153 |
| A    | @    | 185.199.109.153 |
| A    | @    | 185.199.110.153 |
| A    | @    | 185.199.111.153 |

**`www` — one CNAME:**

| Type  | Name | Value                    |
|-------|------|--------------------------|
| CNAME | www  | wshallwshall.github.io   |

(The CNAME target is the GitHub **user** subdomain, not the repo. With the apex set as the
primary custom domain, GitHub redirects `www` → `messagefoundry.org`.)

Clean-up that commonly breaks Pages on GoDaddy:

- **Delete GoDaddy's default parked A record** on `@` and any pre-existing `www` CNAME → `@`.
- **Disable Domain Forwarding** on the domain — it overrides these records.
- *(Optional, IPv6)* add AAAA records on `@`: `2606:50c0:8000::153`, `…8001::153`,
  `…8002::153`, `…8003::153`.

> GitHub's apex IPs above are current but can change. If Pages flags a DNS problem, re-check
> them in GitHub's docs: *Managing a custom domain for your GitHub Pages site*.

## 3. Verify

```bash
nslookup messagefoundry.org      # expect the four 185.199.x.153 addresses
```

When GitHub's DNS check goes green, enable **Enforce HTTPS**, then load
`https://messagefoundry.org` and `https://www.messagefoundry.org` (the latter should
redirect to the apex).

## 4. Ongoing: publish a change

```bash
git add -A
git commit -m "Update site"
git push          # GitHub Pages rebuilds within ~1–2 minutes
```

## Notes

- **Don't delete `CNAME`.** Removing it un-sets the custom domain on the next deploy.
- The `og.svg` social-share image works on most platforms; some networks don't render SVG
  Open Graph images. If share previews matter, export a 1200×630 **PNG** to
  `assets/img/og.png` and update the `og:image` / `twitter:image` URLs.
