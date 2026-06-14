# Architecture

Post Publisher is a small monorepo with two deliverables and supporting docs:

- `code/cli` — the CLI itself, a Dart package named `post_publisher`.
- `code/site` — the static public product site, deployed to GitHub Pages.
- `docs` — architecture notes and ADRs.

## CLI structure

The CLI follows a modular command pattern (built on `modular_cli_sdk` and
`cli_router`): a thin binary entrypoint delegates to a package runtime that
registers command modules.

```
code/cli/
  bin/main.dart            # process entrypoint
  lib/
    post_publisher.dart    # runtime entry; wires up the modules
    modules/
      global/              # help, init, version, doctor, upgrade, uninstall, tui
      auth/                # configure, login, status, logout
      post/                # text, image, document
    src/
      config_store.dart    # user + project config, token + profile models
      linkedin_api.dart    # LinkedIn REST client (auth + posts + media upload)
      oauth.dart           # builds the authorization request (confidential flow)
      url_launcher.dart    # opens the system browser for the OAuth consent
      project_root.dart    # locates the project root for project-level config
      version.dart         # the CLI version constant (source of truth)
      version_check.dart   # latest-release check
    platform/
      platform_ops.dart            # OS-specific operations interface
      windows_platform_ops.dart    # archive expand, PATH, self-replace, etc.
      linux_platform_ops.dart
  scripts/                 # build, install, dev-install, smoke-posts
  assets/templates/        # project_config.json template used by `init`
  test/
```

Each command is an `Input` → `Command` → `Output` triple: the input parses CLI
flags, the command validates and executes, and the output renders text and an
exit code.

## Authentication

Auth uses LinkedIn's **3-legged OAuth Authorization Code flow for confidential
clients** (no PKCE — see [ADR/decision below](#decisions)):

1. `auth configure` stores the client id, client secret, redirect URI, scopes,
   and API version.
2. `auth login` opens the browser to LinkedIn's `/oauth/v2/authorization`
   endpoint, runs a loopback HTTP server on the redirect URI to capture the
   authorization code, then exchanges it at `/oauth/v2/accessToken` using the
   client secret.
3. The access token and the resolved member profile (`/v2/userinfo`) are cached
   in the user config file.

Tokens last ~60 days; there is no refresh token (LinkedIn gates that behind
additional approval), so re-login is manual after expiry.

## Publishing

All posts go to the LinkedIn REST API `/rest/posts` endpoint with the
`LinkedIn-Version` header. Media is uploaded in two steps:

- Initialize an upload (`/rest/images` or `/rest/documents` with
  `action=initializeUpload`) to get an upload URL and an asset URN.
- `PUT` the file bytes to the upload URL, then create the post referencing the
  asset URN.

The post author is an URN, resolved as: `--organization` flag → project
`defaultOrganizationUrn` → the authenticated member's `urn:li:person:*`. (Org
posting is wired but unused — see Scope.)

## Configuration

- User-level config (credentials, token, profile) lives in the OS config dir:
  - Windows: `%APPDATA%/post_publisher/config.json`
  - Linux: `~/.config/post_publisher/config.json`
  - macOS: `~/Library/Application Support/post_publisher/config.json`
- Project-level defaults live in `.post_publisher/config.json`, created by
  `post-publisher init`.

Because user config is separate from the install directory, installing,
upgrading, or uninstalling the binary never touches your saved credentials.

## Distribution

- `release.yml` compiles the binary on Windows and Linux runners, packages it as
  `post-publisher-windows-x64.zip` / `post-publisher-linux-x64.tar.gz` (each
  containing `bin/<binary>` and `assets/`), and publishes a GitHub Release
  `v<version>`
  whenever `version.dart` is bumped on `main`.
- `pages.yml` deploys `code/site` and bundles `install.ps1` / `install.sh` so
  they are served from the product domain.
- `install.*` download the latest release and add it to `PATH`; `upgrade`
  self-updates from the latest release; `uninstall` removes the install dir and
  the `PATH` entry.

## Scope

Publishing as the personal member profile (`w_member_social`) is supported.
Native organization posting is out of scope: LinkedIn's Community Management API
requires a dedicated app with an institutional email. Org reach is achieved by
publishing personally and resharing from Pages.

## Decisions

Architecture Decision Records live in [`adr/`](adr/). Notable runtime decision:
the OAuth token exchange uses the confidential flow with the client secret and
**no PKCE** — mixing PKCE onto LinkedIn's standard authorization endpoint makes
it treat the client as public and reject the secret (`401 invalid_client`).
