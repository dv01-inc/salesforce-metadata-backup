#!/bin/bash

DATE=$(date +"%Y-%m-%d")

# Retrieve metadata
sf project retrieve start \
  --manifest manifest/package.xml \
  --target-org prod

# Commit changes
git add .
git commit -m "Daily Salesforce metadata backup - $DATE"

# Push
git push origin main
