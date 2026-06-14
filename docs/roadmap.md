# Roadmap

## Shipped — v0.1.0

- [x] Modular CLI scaffold (global / auth / post command modules)
- [x] 3-legged OAuth login with loopback callback (confidential flow)
- [x] Personal text post, end to end against the live LinkedIn API
- [x] Image post (asset upload via `/rest/images`)
- [x] PDF document post (asset upload via `/rest/documents`)
- [x] `doctor`, `auth status`, and a smoke-test script
- [x] Public product site + privacy policy at post-publisher.ccisne.dev
- [x] Cross-platform release pipeline (Windows + Linux binaries)
- [x] One-line web installer + `upgrade` / `uninstall`

## Next ideas (unscheduled)

- Automate resharing a personal post from each owned Page (the current
  workaround is a manual reshare for organization reach).
- Native organization posting (`w_organization_social`) — blocked on LinkedIn's
  Community Management API, which needs a dedicated app and an institutional
  email. Revisit if those become available.
- Token lifecycle: surface expiry clearly and streamline the ~60-day re-login.
- Code-signing the release binaries (Windows/macOS) to reduce SmartScreen and
  Gatekeeper friction.
- macOS release target (currently Windows + Linux only).
- Rename the technical command/binary from `linkedin` to `post_publisher` for
  consistency with the product name.

## Backlog

- Richer post content (multi-image, articles, polls).
- Scheduling / queued posts.
- Optional non-interactive auth path for CI environments.
