#!/usr/bin/env bash
set -euo pipefail

# rebuild.sh for oasisprotocol/docs
# Docusaurus 3.9.2, Yarn 1 Classic 1.22.22, Node >= 20
# Runs on existing source tree (no clone). Installs deps and builds.
# Does NOT run write-translations.

export PATH="/usr/local/bin:/usr/bin:/bin"
export HOME="${HOME:-/root}"

# ── Node version management ────────────────────────────────────────────────
export NVM_DIR="${HOME}/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  source "$NVM_DIR/nvm.sh"
fi

NODE_VERSION="20"
if command -v nvm &>/dev/null; then
  nvm install "$NODE_VERSION" --no-progress
  nvm use "$NODE_VERSION"
elif command -v node &>/dev/null; then
  echo "Using system node: $(node --version)"
else
  echo "ERROR: No Node.js found. Please install Node.js $NODE_VERSION+."
  exit 1
fi

echo "Node: $(node --version)"
echo "npm:  $(npm --version)"

# ── Ensure yarn classic is available ──────────────────────────────────────
if ! command -v yarn &>/dev/null; then
  echo "Installing yarn classic..."
  npm install -g yarn@1.22.22 --quiet
fi
echo "Yarn: $(yarn --version)"

# ── Install dependencies ────────────────────────────────────────────────────
echo "Installing dependencies..."
yarn install --frozen-lockfile

# ── Build ───────────────────────────────────────────────────────────────────
echo "Running build..."
yarn build

# ── Verify build output ─────────────────────────────────────────────────────
if [ -d "build" ] && [ "$(ls -A build)" ]; then
  echo "SUCCESS: build/ directory exists and contains files"
else
  echo "ERROR: build/ directory missing or empty"
  exit 1
fi

echo "[DONE] Build complete."
