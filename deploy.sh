#!/bin/bash
set -e

BRANCH=$1       # dev або main
DOMAIN=$2       # наприклад, dev.iatnih.pp.ua
EMAIL=$3        # email для Let's Encrypt
BG_COLOR=$4     # наприклад, green або purple

if [ -z "$BRANCH" ] || [ -z "$DOMAIN" ] || [ -z "$EMAIL" ] || [ -z "$BG_COLOR" ]; then
    echo "Usage: $0 <branch> <domain> <email> <bg_color>"
    exit 1
fi

echo "📦 Deploy branch: $BRANCH"
echo "🌐 Domain: $DOMAIN"
echo "🎨 Background color: $BG_COLOR"

# Gen .env
cat > .env <<EOF
BG_COLOR=$BG_COLOR
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF

# update and up
docker-compose down
docker-compose up -d --build

# chek HTTPS
echo "🔍 Checking HTTPS..."
if curl -s --head "https://$DOMAIN" | grep "200 OK" > /dev/null; then
    echo "✅ Site is available over HTTPS"
else
    echo "❌ Site is not available over HTTPS"
    exit 1
fi

# Check cert
echo "🔍 Checking SSL certificate..."
EXPIRY_DATE=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
echo "📅 Certificate expires on: $EXPIRY_DATE"
