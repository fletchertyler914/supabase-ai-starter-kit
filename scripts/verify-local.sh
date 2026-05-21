#!/usr/bin/env bash

set -euo pipefail

echo "==> Preparing local verification environment"
if [ ! -f ".env" ]; then
  cp .env.example .env
fi

mkdir -p volumes/n8n volumes/db/data volumes/storage
chmod -R 777 volumes/n8n volumes/db/data volumes/storage

echo "==> Validating compose configurations"
docker compose config --quiet
docker compose -f docker-compose.yml -f docker/docker-compose.dev.yml config --quiet
docker compose -f docker-compose.yml -f docker/docker-compose.email.yml config --quiet
docker compose -f docker-compose.yml -f docker/docker-compose.s3.yml config --quiet
docker compose -f docker-compose.yml -f docker/docker-compose.dev.yml -f docker/docker-compose.email.yml -f docker/docker-compose.s3.yml config --quiet

echo "==> Starting full stack"
npm run dev:full

echo "==> Waiting for core endpoints"
for i in {1..40}; do
  KONG_STATUS="$(curl --connect-timeout 2 --max-time 3 -s -o /dev/null -w "%{http_code}" http://localhost:8000/health || true)"
  N8N_STATUS="$(curl --connect-timeout 2 --max-time 3 -s -o /dev/null -w "%{http_code}" http://localhost:5678 || true)"
  ANALYTICS_STATUS="$(curl --connect-timeout 2 --max-time 3 -s -o /dev/null -w "%{http_code}" http://localhost:4000/health || true)"
  echo "attempt=$i kong=$KONG_STATUS n8n=$N8N_STATUS analytics=$ANALYTICS_STATUS"
  if [ "$KONG_STATUS" = "401" ] && [ "$N8N_STATUS" = "200" ] && [ "$ANALYTICS_STATUS" = "200" ]; then
    echo "Core endpoints are ready."
    break
  fi
  if [ "$i" -eq 40 ]; then
    echo "Timed out waiting for core endpoints."
    docker compose ps
    exit 1
  fi
  sleep 5
done

echo "==> Running test suite"
npm test

echo "==> Verification passed"
