# jessabekker.be: context for Claude

Jessa's personal domain. The root (`site/public/`) is **public**: a bare
placeholder now, later a business website (services, expertise); not being
built yet. Household apps and private (pre-trial) projects live under
**`/tools/`, family only**. README.md has the layout, setup and how to add an app.
Workspace-wide context is in `../CLAUDE.md`; the server itself (setup,
shared Caddy, backups) is in `../server`.

- UI text Dutch; code, comments, docs and commits English.
- Access control is **one gate for `/tools/`** (and any family subdomain): Caddy `forward_auth`
  to oauth2-proxy (Google sign-in + `allowed-emails.txt` allow-list). Apps
  behind it have no login of their own and read the visitor from
  `X-Auth-Request-Email` / `X-Auth-Request-User`. The Caddy snippet strips
  those headers from incoming requests first; keep that for every new site
  block, or a visitor could fake them.
- Every new app: own container on the `edge` network, own data in
  `/opt/apps/<app>/data/` (backed up nightly by ../server), and a
  `/tools/<app>/` route or subdomain with `import jessabekker_login`.
  Anything outside `/tools/` and `/oauth2/` is public: never put family
  content there. Never give these containers access
  to `/opt/apps/cork-e/` (families' data).
- Secrets live only on the server (`/opt/apps/jessabekker/auth.env`). The
  Google Cloud project is separate from Cork-e's and stays in Testing mode;
  family members must be on both allow-lists (Google test users and
  `allowed-emails.txt`).
- oauth2-proxy is pinned (`deploy/compose.yml`) and not auto-updated; bump it
  when there's a security release.
