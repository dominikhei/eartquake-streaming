#!/bin/bash
set -e

infracost breakdown \
  --path=. \
  --usage-file=infracost-usage.yml \
  --format=json \
  --out-file=infracost.json

if [ ! -f infracost.json ]; then
  echo "Error: infracost.json not found!"
  exit 1
fi

export INFRACOST=$(jq -c . < infracost.json)

if [ ! -f index.html ]; then
  echo "Error: dashboard.html not found!"
  exit 1
fi

sed -i.bak "s|\$INFRACOST|$INFRACOST|" index.html