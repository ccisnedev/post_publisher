# LinkedIn CLI

Publish to LinkedIn from the command line.

This package follows the same modular UX pattern as the Inquiry CLI: a thin binary entrypoint, a package-level runtime entry, global commands, and dedicated modules for auth and posting.

## Status

This is the initial open-source scaffold.

What already works:

- Global UX commands: `help`, `init`, `version`, `doctor`, `upgrade`, `uninstall`
- LinkedIn auth configuration: `auth configure`
- OAuth sign-in flow: `auth login` and `auth signin`
- Auth inspection: `auth status`, `auth logout`
- Text posting: `post text`
- Image posting from local files: `post image`
- PDF posting from local files: `post document`

## Open-source configuration model

This CLI is designed for any user to bring their own LinkedIn app credentials.

The expected setup is:

1. Create a LinkedIn Developer application.
2. Enable the products you need.
3. Configure your own `client id`, `client secret`, and `redirect uri`.
4. Run `linkedin auth configure`.
5. Run `linkedin auth login`.
6. Run `linkedin post text --message "Hello from LinkedIn CLI"`.
7. Optionally run `linkedin post image --file ./hello.png --message "Hello, LinkedIn!"`.
8. Optionally run `linkedin post document --file ./hello.pdf --message "Hello, LinkedIn!"`.

The CLI does not embed secrets and does not assume shared credentials.

## LinkedIn products you need

For personal posting:

- `Sign in with LinkedIn using OpenID Connect`
- `Share on LinkedIn`

For organization posting:

- `Community Management API` or another approved product that grants `w_organization_social`
- A valid role on the LinkedIn Page you want to post as

## Local configuration

Machine-level configuration is stored in the user config directory:

- Windows: `%APPDATA%/post_publisher/config.json`
- Linux: `~/.config/post_publisher/config.json`
- macOS: `~/Library/Application Support/post_publisher/config.json`

Project-level defaults live in:

- `.post_publisher/config.json`

Create that file with:

```bash
linkedin init
```

## Commands

| Command | Purpose |
|---|---|
| `linkedin` | Show status and quick-start guidance |
| `linkedin help` | Show the command summary |
| `linkedin init` | Create project-level defaults in `.post_publisher/config.json` |
| `linkedin version` | Print the current CLI version |
| `linkedin doctor` | Verify the local setup for auth and posting |
| `linkedin upgrade` | Download and install the latest release |
| `linkedin uninstall` | Remove the CLI from the system |
| `linkedin auth configure` | Save LinkedIn app credentials locally |
| `linkedin auth login` | Run the LinkedIn OAuth flow |
| `linkedin auth signin` | Alias for `auth login` |
| `linkedin auth status` | Show the cached auth status |
| `linkedin auth logout` | Remove the cached token |
| `linkedin post text --message ...` | Publish a text post |
| `linkedin post image --file ... --message ...` | Publish an image post |
| `linkedin post document --file ... --message ...` | Publish a PDF document post |

## Quick start from source

### Windows

```powershell
Set-Location code/cli
dart pub get
dart run bin/main.dart help
```

### Linux/macOS

```bash
cd code/cli
dart pub get
dart run bin/main.dart help
```

## Configure your LinkedIn app

Example:

```bash
linkedin auth configure \
  --client-id "YOUR_CLIENT_ID" \
  --client-secret "YOUR_CLIENT_SECRET" \
  --redirect-uri "http://127.0.0.1:8787/callback" \
  --scopes "openid profile email w_member_social"
```

You can also provide the same values through environment variables:

- `LINKEDIN_CLIENT_ID`
- `LINKEDIN_CLIENT_SECRET`
- `LINKEDIN_REDIRECT_URI`
- `LINKEDIN_SCOPES`
- `LINKEDIN_API_VERSION`

## Sign in

Standard flow:

```bash
linkedin auth login
```

Manual fallback:

```bash
linkedin auth login --manual
```

If the CLI cannot capture the loopback redirect automatically, it falls back to asking you to paste the full redirect URL.

## Publish a post

Publish as your personal profile:

```bash
linkedin post text --message "Hello from my open-source LinkedIn CLI"
```

Publish as an organization:

```bash
linkedin post text \
  --organization "urn:li:organization:123456" \
  --message "Posting on behalf of my organization"
```

Publish an image from a local file:

```bash
linkedin post image \
  --file ./hello.png \
  --message "Hello, LinkedIn!" \
  --alt-text "Simple greeting image"
```

Publish a PDF document:

```bash
linkedin post document \
  --file ./hello.pdf \
  --title "hello.pdf" \
  --message "Hello, LinkedIn!"
```

Windows smoke test script:

```powershell
.\scripts\smoke-posts.ps1
```

Preview the commands without publishing:

```powershell
.\scripts\smoke-posts.ps1 -DryRun
```

## Build and install from source

Windows:

```powershell
.\scripts\dev-install.ps1
```

Linux/macOS:

```bash
./scripts/dev-install.sh
```