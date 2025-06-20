#!/bin/sh
set -e
GRAFANA_URL="http://grafana:3000"

# espera a que grafana esté disponible
until curl -s "$GRAFANA_URL/api/health" >/dev/null; do
  echo "Esperando a Grafana..."
  sleep 5
done

API_URL="$GRAFANA_URL/api/datasources"

cat <<'JSON' > /tmp/cloudwatch.json
{
  "name": "CloudWatch",
  "type": "cloudwatch",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "authType": "default",
    "defaultRegion": "us-east-1"
  }
}
JSON

curl -s -u admin:admin -H "Content-Type: application/json" -X POST "$API_URL" -d @/tmp/cloudwatch.json

# importar dashboards desde /dashboards
for dash in /dashboards/*.json; do
  [ -f "$dash" ] || continue
  DATA=$(jq -c '.' "$dash")
  curl -s -u admin:admin -H "Content-Type: application/json" -X POST \
    "$GRAFANA_URL/api/dashboards/db" \
    -d "{\"dashboard\":$DATA,\"overwrite\":true}"
done
