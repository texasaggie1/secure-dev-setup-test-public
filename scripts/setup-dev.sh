#!/bin/sh
# Run this once in every new copy of the repo: sh scripts/setup-dev.sh
# It turns on the safety hooks. On Windows, run it in Git Bash.

root=$(git rev-parse --show-toplevel) || exit 1
cd "$root" || exit 1

git config core.hooksPath .githooks
chmod +x .githooks/pre-commit .githooks/pre-push scripts/*.sh
echo "OK: safety hooks are on."

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "MISSING: gitleaks. Commits are blocked until it is installed."
  echo "On a Mac: brew install gitleaks"
  echo "Other systems: https://github.com/gitleaks/gitleaks/releases"
  exit 1
fi
echo "OK: gitleaks is installed."

if [ ! -f .env ]; then
  echo "NOTE: no .env file here yet. Copy .env.example to .env and fill in the values yourself."
fi
