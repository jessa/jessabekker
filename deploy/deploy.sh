#!/bin/bash
# Deploy jessabekker.be from the Mac to the server (set up with ../server first).
#
#   deploy/deploy.sh          upload the site (public + tools) and the login gate, restart, reload Caddy
#   deploy/deploy.sh emails   edit who may sign in (allowed-emails.txt) and apply it
#   deploy/deploy.sh status   show the login container and its last log lines
#
# Server: SERVER_HOST (default deploy@app.cork-e.eu, the same machine).
set -euo pipefail
cd "$(dirname "$0")/.."

HOST="${SERVER_HOST:-deploy@app.cork-e.eu}"
APP=/opt/apps/jessabekker

prepare_server() {
    ssh "$HOST" "install -d $APP /opt/www/jessabekker"
    # First time: secrets file with a fresh cookie secret, and the allow-list with Jessa only.
    ssh "$HOST" "[ -f $APP/auth.env ] || { install -m 600 /dev/null $APP/auth.env && sed \"s|^OAUTH2_PROXY_COOKIE_SECRET=.*|OAUTH2_PROXY_COOKIE_SECRET=\$(openssl rand -base64 32 | tr -- '+/' '-_')|\" > $APP/auth.env; }" < deploy/auth.env.example
    ssh "$HOST" "[ -f $APP/allowed-emails.txt ] || cat > $APP/allowed-emails.txt" < deploy/allowed-emails.example
}

restart_auth() {
    ssh "$HOST" "cd $APP && docker compose up -d --force-recreate --remove-orphans"
}

case "${1:-}" in
    "")
        prepare_server
        if ! ssh "$HOST" "grep -q '^OAUTH2_PROXY_CLIENT_ID=.' $APP/auth.env"; then
            echo "Fill in the Google client in $APP/auth.env on the server first:" >&2
            echo "  ssh -t $HOST nano $APP/auth.env" >&2
            exit 1
        fi
        rsync -az --delete site/ "$HOST:/opt/www/jessabekker/"
        rsync -az deploy/compose.yml "$HOST:$APP/compose.yml"
        restart_auth
        rsync -az deploy/jessabekker.caddy "$HOST:/opt/edge/sites/jessabekker.caddy"
        ssh "$HOST" 'cd /opt/edge && docker compose exec -T caddy caddy reload --config /etc/caddy/Caddyfile'
        ;;
    emails)
        ssh -t "$HOST" "nano $APP/allowed-emails.txt"
        restart_auth
        echo "Remember: each address must also be a test user in the Google Cloud project."
        ;;
    status) ssh "$HOST" "cd $APP && docker compose ps && docker compose logs --tail 30" ;;
    *) sed -n '2,8p' "$0"; exit 1 ;;
esac
