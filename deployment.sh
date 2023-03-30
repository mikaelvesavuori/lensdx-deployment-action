#!/bin/bash -l

set -o pipefail

API_KEY="${1}"
if [ -z "$API_KEY" ]; then echo "LensDX error: API key is not set! Exiting..." && exit 1; fi

REPO_NAME="$GITHUB_REPOSITORY"

ENDPOINT="https://dorametrix.lensdx.app"

# Get current Git SHA
CURRENT_GIT_SHA=$(git log --pretty=format:'%H' -n 1)

# Get commit ID of last production deployment
LAST_PROD_DEPLOY=$(curl "$ENDPOINT/lastdeployment?product=$REPO_NAME" -H 'Authorization: "$API_KEY"' | jq '.id' -r)

if [[ -z "$LAST_PROD_DEPLOY" ]] || [[ "$LAST_PROD_DEPLOY" == "null" ]]; then
  # If no LAST_PROD_DEPLOY is found, then very defensively assume that the first commit is most recent deployment
  LAST_PROD_DEPLOY=$(git rev-list HEAD | tail -n 1)
fi

# Verify that commits exist
if ! git --no-pager log $LAST_PROD_DEPLOY..$CURRENT_GIT_SHA --decorate=short --pretty=oneline; then exit 1; fi

# Get all commits between current work and last production deployment then put result in local TXT file
git log $LAST_PROD_DEPLOY..$CURRENT_GIT_SHA --pretty=format:'{%n  ^^^^id^^^^: ^^^^%H^^^^,%n  ^^^^timeCreated^^^^: ^^^^%ct^^^^%n  },' | sed 's/"/\\"/g' | sed 's/\^^^^/"/g' | sed "$ s/,$//" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | awk 'BEGIN { print("[") } { print($0) } END { print("]") }' >commits.json

# Use TXT output to set variable with list of commits
CHANGES=$(cat commits.json | jq '[.[] | { id: .id, timeCreated: .timeCreated }]')
CHANGES_LENGTH=$(echo $CHANGES | jq '. | length' -r)

# Remove the scratch TXT file
rm commits.json

# No changes found
if [[ $CHANGES_LENGTH -eq 0 ]]; then exit 1; fi

# Call LensDX and create deployment event with Git changes
curl -X POST $ENDPOINT/event?authorization="$API_KEY" -d '{ "eventType": "deployment", "repo": "'$REPO_NAME'", "changes": '"$CHANGES"' }' -H "Content-Type: application/json" -s