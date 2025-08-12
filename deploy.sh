#!/bin/bash
set -e

BRANCH=$1       
DOMAIN=$2       
EMAIL=$3        
BG_COLOR=$4     

if [ "$BRANCH" != "main" ]; then
    echo "Error: This deploy script supports only 'main' branch"
    exit 1
fi

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ] || [ -z "$BG_COLOR" ]; then
    echo "Usage: $0 main <domain> <email> <bg_color>"
    exit 1
fi

echo "📦 Deploy branch: $BRANCH"
echo "🌐 Domain: $DOMAIN"
echo "🎨 Background color: $BG_COLOR"

# .env 
cat > .env <<EOF
PROD_BG_COLOR=$BG_COLOR
PROD_PORT=3001
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF

# We define the project name and compose file for production
PROJECT_NAME="devops-test-prod"
COMPOSE_FILE="docker-compose.prod.yml"

# Stop and remove old production containers along with orphans
docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME down --remove-orphans

# Launching production containers
docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME up -d --build

# Checking HTTPS availability with retrieso
echo "🔍 Checking HTTPS availability..."

MAX_RETRIES=5
SLEEP_TIME=5
COUNT=0
while [ $COUNT -lt $MAX_RETRIES ]; do
  if curl -s --head "https://$DOMAIN" | grep "200 OK" > /dev/null; then
    echo "✅ Site is available over HTTPS"
    break
  else
    echo "⏳ Waiting for site to be available... retry $((COUNT+1))/$MAX_RETRIES"
    COUNT=$((COUNT+1))
    sleep $SLEEP_TIME
  fi
done

if [ $COUNT -eq $MAX_RETRIES ]; then
  echo "❌ Site is not available over HTTPS after retries"
  exit 1
fi

# Checking SSL certificate
echo "🔍 Checking SSL certificate..."
EXPIRY_DATE=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
echo "📅 Certificate expires on: $EXPIRY_DATE"
