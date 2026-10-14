# jessabekker.be

Jessa's personal site: household apps and private trials, for family only.
Everything on `jessabekker.be` (and later `*.jessabekker.be`) sits behind one
login: **Sign in with Google**, and only addresses on an allow-list get in.

```
browser ──▶ shared Caddy (../server)
              ├── /oauth2/*  → login gate (oauth2-proxy, Google)
              └── anything else: Caddy first asks the gate "is this visitor
                  signed in and on the list?" → yes: serve the page or app,
                  no: send them to Google sign-in
```

Apps behind the gate don't need their own login: Caddy passes who is
visiting in the `X-Auth-Request-Email` and `X-Auth-Request-User` headers.

```
site/                    home page (static; shows who is signed in)
deploy/compose.yml       the login gate (oauth2-proxy), on the server's "edge" network
deploy/jessabekker.caddy Caddy site file: home page, login, www redirect, app template
deploy/deploy.sh         deploy from the Mac; also edits the allow-list
deploy/*.example         templates for the server-side secrets and allow-list
```

## Setup (one-time)

1. **Server**: set up with `../server` first (shared Caddy).
2. **DNS** (Combell, zone `jessabekker.be`): A record `@` → the server's IPv4
   address, and CNAME `www` → `jessabekker.be`. Leave mail (MX) records alone.
3. **Google Cloud**: a separate project, so the sign-in screen shows this
   site and not Cork-e:
   - New project, e.g. `jessabekker`.
   - **Branding**: app name `jessabekker.be`, your Gmail as support email,
     home page `https://jessabekker.be`, authorised domain `jessabekker.be`.
   - **Audience**: External, leave on **Testing**, add each family member's
     Google address as a test user.
   - **Data access**: `openid`, `userinfo.email`, `userinfo.profile`.
   - **Clients → Web application**, redirect URI
     `https://jessabekker.be/oauth2/callback`.
4. **Deploy** once; it creates the server-side files and stops:
   ```bash
   deploy/deploy.sh
   ssh -t deploy@app.cork-e.eu nano /opt/apps/jessabekker/auth.env   # client ID + secret
   deploy/deploy.sh
   ```
5. **Family members**: `deploy/deploy.sh emails`, one Google address per
   line. Each must also be a test user in the Google Cloud project; that's a
   second, independent allow-list.

## Adding an app later

Run it as its own container on the `edge` network (own compose project, own
data in `/opt/apps/<app>/data/`, picked up by the nightly backup), then add a
subdomain block to `deploy/jessabekker.caddy` with `import jessabekker_login`
(there's a commented example) and a DNS record for the subdomain.

## Maintenance

The login gate is a security component and isn't updated by the server's
automatic updates. A few times a year, check
<https://github.com/oauth2-proxy/oauth2-proxy/releases>, bump the version in
`deploy/compose.yml`, and run `deploy/deploy.sh`.
