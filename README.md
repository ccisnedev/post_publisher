# Post Publisher

Open-source command-line tool for publishing to LinkedIn — text, images, and PDF
documents — straight from your terminal.

Post Publisher uses standard LinkedIn OAuth with a **bring-your-own-credentials**
model: you connect your own LinkedIn Developer app, so you stay in full control
of your access and data. Sign in once, then make your posting flow scriptable
and repeatable.

- Website: https://post-publisher.ccisne.dev
- Privacy policy: https://post-publisher.ccisne.dev/privacy/publisher

## Repository layout

```
code/
  cli/      # The Post Publisher CLI (Dart package `post_publisher`)
  site/     # The public product site (served via GitHub Pages)
docs/
  adr/      # Architecture Decision Records
  architecture.md
.github/
  workflows/
    pages.yml     # Deploy code/site to GitHub Pages + serve the installers
    release.yml   # Build Windows/Linux binaries and publish a GitHub Release
```

## Install

Windows (PowerShell):

```powershell
irm https://post-publisher.ccisne.dev/install.ps1 | iex
```

Linux (bash):

```bash
curl -fsSL https://post-publisher.ccisne.dev/install.sh | bash
```

The installer downloads the latest release binary from GitHub and adds it to
your `PATH`. Both scripts are public and reviewable at
`/install.ps1` and `/install.sh`.

## Quick start

Post Publisher ships no shared secrets. Create your own LinkedIn Developer app
(enable **Sign in with LinkedIn using OpenID Connect** and **Share on LinkedIn**),
then point the CLI at it:

```bash
linkedin auth configure   # store your client id, secret, redirect URI
linkedin auth login       # sign in once through the browser
linkedin post text --message "Hello, LinkedIn!"
```

Publish media the same way:

```bash
linkedin post image --file ./photo.png --message "..." --alt-text "..."
linkedin post document --file ./deck.pdf --title "deck.pdf" --message "..."
```

After signing in, posting is fully scriptable until the token expires
(~60 days), then you sign in again.

For the full command reference, configuration paths, and development setup, see
[`code/cli/README.md`](code/cli/README.md). For the design, see
[`docs/architecture.md`](docs/architecture.md).

## Scope

- Publishing as your **personal** LinkedIn profile (`w_member_social`).
- Posting natively as an **organization** is out of scope: LinkedIn's Community
  Management API requires a dedicated app with an institutional email. The
  intended path for org reach is to publish personally and reshare from your
  Pages.
