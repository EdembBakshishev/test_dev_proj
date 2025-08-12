#!/bin/bash
set -e

BRANCH=$1       # main
DOMAIN=$2       # наприклад, prod.iatnih.pp.ua
EMAIL=$3        # email для Let's Encrypt
BG_COLOR=$4     # наприклад, purple

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

# Генеруємо .env для продакшену
cat > .env <<EOF
PROD_BG_COLOR=$BG_COLOR
PROD_PORT=3001
DOMAIN=$DOMAIN
EMAIL=$EMAIL
EOF

# Визначаємо ім'я проекту та compose файл для продакшену
PROJECT_NAME="devops-test-prod"
COMPOSE_FILE="docker-compose.prod.yml"

# Зупиняємо і видаляємо старі контейнери продакшену разом з орфанами
docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME down --remove-orphans

# Запускаємо продакшен контейнери
docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME up -d --build

# Перевіряємо HTTPS доступність із повторними спробами
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

# Перевіряємо SSL сертифікат
echo "🔍 Checking SSL certificate..."
EXPIRY_DATE=$(echo | openssl s_client -connect "$DOMAIN:443" -servername "$DOMAIN" 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2)
echo "📅 Certificate expires on: $EXPIRY_DATE"
