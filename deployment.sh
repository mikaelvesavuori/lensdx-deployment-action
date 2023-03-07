#!/bin/bash -l

set -o pipefail

echo "✨ Running Dorametrix deployment event script..."

# Set variables
#if [ -z "$ENDPOINT" ]; then ENDPOINT="$1"; fi # Input from user when calling the action
ENDPOINT="https://dorametrix.lensdx.app"
echo "ℹ️ ENDPOINT --> $ENDPOINT"
if [ -z "$ENDPOINT" ]; then echo "Dorametrix error: ENDPOINT is not set! Exiting..." && exit 1; fi

#if [ -z "$API_KEY" ]; then API_KEY="$2"; fi # Input from user when calling the action
API_KEY="7RaSwogUK7=t6r_spfgo8r9Ph0dZ"
#if [ -z "$API_KEY" ]; then echo "Dorametrix error: API_KEY is not set! Exiting..." && exit 1; fi

#if [ -z "$REPO_NAME" ]; then REPO_NAME="$3"; fi # Input from user when calling the action
REPO_NAME="SOMEORG/SOMEREPO"
echo "ℹ️ REPO_NAME --> $REPO_NAME"
if [ -z "$REPO_NAME" ]; then echo "Dorametrix error: REPO_NAME is not set! Exiting..." && exit 1; fi

# Get current Git SHA
CURRENT_GIT_SHA=$(git log --pretty=format:'%H' -n 1)
echo "ℹ️ CURRENT_GIT_SHA --> $CURRENT_GIT_SHA"

# Get commit ID of last production deployment
LAST_PROD_DEPLOY=$(curl "$ENDPOINT/lastdeployment?product=$REPO_NAME" -H 'Authorization: "$API_KEY"' | jq '.id' -r)

# If no LAST_PROD_DEPLOY is found, then very defensively assume that the first commit is most recent deployment
if [[ -z "$LAST_PROD_DEPLOY" ]] || [[ "$LAST_PROD_DEPLOY" == "null" ]]; then
  echo "⚠️ Dorametrix warning: Could not find a value for LAST_PROD_DEPLOY. Setting LAST_PROD_DEPLOY to the value of the first commit."
  LAST_PROD_DEPLOY=$(git rev-list HEAD | tail -n 1) #git rev-list --max-parents=0 HEAD
fi
echo "ℹ️ LAST_PROD_DEPLOY --> $LAST_PROD_DEPLOY"

echo "Verifying that commits exist..."
if ! git --no-pager log $LAST_PROD_DEPLOY..$CURRENT_GIT_SHA --decorate=short --pretty=oneline; then
  echo "🔥 Dorametrix error: Unable to find the expected commits in working tree! Exiting..."
  exit 1
fi

# Get all commits between current work and last production deployment then put result in local TXT file
git log $LAST_PROD_DEPLOY..$CURRENT_GIT_SHA --pretty=format:'{%n  ^^^^id^^^^: ^^^^%H^^^^,%n  ^^^^timeCreated^^^^: ^^^^%ct^^^^%n  },' | sed 's/"/\\"/g' | sed 's/\^^^^/"/g' | sed "$ s/,$//" | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | awk 'BEGIN { print("[") } { print($0) } END { print("]") }' >commits.json

# Use TXT output to set variable with list of commits
CHANGES=$(cat commits.json | jq '[.[] | { id: .id, timeCreated: .timeCreated }]')
#echo "ℹ️ CHANGES --> $CHANGES"
CHANGES_LENGTH=$(echo $CHANGES | jq '. | length' -r)
#echo "ℹ️ CHANGES_LENGTH --> $CHANGES_LENGTH"

# Remove the scratch TXT file
rm commits.json

if [[ $CHANGES_LENGTH -eq 0 ]]; then
  echo "🔥 Dorametrix error: No changes detected. Exiting..."
  exit 1
fi

# Call Dorametrix and create deployment event with Git changes
curl -X POST $ENDPOINT/event?authorization="$API_KEY" -d '{ "eventType": "deployment", "repo": "'$REPO_NAME'", "changes": '"$CHANGES"' }' -H "Content-Type: application/json"

echo -e "\n✅ Dorametrix deployment script has finished successfully!"