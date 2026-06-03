#!/usr/bin/env bash
# Launches n8n locally with this project's .env loaded.
# First run downloads n8n (~300MB) and may take a minute.

set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "No .env found. Copy .env.example to .env first."
  exit 1
fi

# Load .env (skip comments and blank lines)
set -a
# shellcheck disable=SC1091
source .env
set +a

# Keep n8n data inside the project so it's portable
export N8N_USER_FOLDER="$(pwd)/.n8n"
mkdir -p "$N8N_USER_FOLDER"

# Allow workflows to read env vars via {{ $env.X }}
export N8N_BLOCK_ENV_ACCESS_IN_NODE=${N8N_BLOCK_ENV_ACCESS_IN_NODE:-false}
export N8N_RUNNERS_ENABLED=${N8N_RUNNERS_ENABLED:-true}
export N8N_SECURE_COOKIE=${N8N_SECURE_COOKIE:-false}

if ! command -v n8n >/dev/null 2>&1; then
  echo "n8n is not installed. Install it once with:"
  echo "    sudo npm install -g n8n"
  echo "Then re-run this script."
  exit 1
fi

echo "Starting n8n at http://localhost:5678"
echo "Data folder: $N8N_USER_FOLDER"
echo "Reports are downloaded from the Build Report node output."
echo ""

exec n8n
