#!/usr/bin/env bash
set -euo pipefail

# prepare.sh for oasisprotocol/docs
# Docusaurus 3.9.2, Yarn 1 Classic 1.22.22, Node >= 20
# Clones repo and installs dependencies. Does NOT run write-translations or build.

REPO_URL="https://github.com/oasisprotocol/docs"
BRANCH="main"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# ── Clone (skip if already exists) ────────────────────────────────────────
if [ ! -d "$REPO_DIR" ]; then
  echo "Cloning $REPO_URL (with submodules)..."
  git clone --depth=1 --branch "$BRANCH" --recurse-submodules "$REPO_URL" "$REPO_DIR"
else
  echo "Source repo already exists, skipping clone."
fi

cd "$REPO_DIR"

# ── Install dependencies ────────────────────────────────────────────────────
echo "Installing dependencies..."
yarn install --frozen-lockfile

# ── Apply fixes.json if present ───────────────────────────────────────────
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
  echo "[INFO] Applying content fixes..."
  node -e "
const fs = require('fs');
const path = require('path');
const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
for (const [file, ops] of Object.entries(fixes.fixes || {})) {
    if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
    let content = fs.readFileSync(file, 'utf8');
    for (const op of ops) {
        if (op.type === 'replace' && content.includes(op.find)) {
            content = content.split(op.find).join(op.replace || '');
            console.log('  fixed:', file, '-', op.comment || '');
        }
    }
    fs.writeFileSync(file, content);
}
for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
    const c = typeof cfg === 'string' ? cfg : cfg.content;
    fs.mkdirSync(path.dirname(file), {recursive: true});
    fs.writeFileSync(file, c);
    console.log('  created:', file);
}
"
fi

echo "[DONE] Repository is ready for docusaurus commands."
