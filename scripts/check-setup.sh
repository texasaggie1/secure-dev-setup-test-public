#!/bin/sh
# Proves this repo still has its safety setup. It changes nothing here.
#   sh scripts/check-setup.sh           check the setup
#   sh scripts/check-setup.sh --prove   also try to break the rules in a throwaway copy
# FAIL means fix it before going on. WARN means a person should know about it.
# On Windows, run it in Git Bash.

fails=0
warns=0
pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; fails=$((fails + 1)); }
warn() { echo "WARN  $1"; warns=$((warns + 1)); }

root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "FAIL  this folder is not a git repo"; exit 1; }
cd "$root" || exit 1

echo "--- Project memory"
for f in CLAUDE.md AGENTS.md SESSIONS.md .env.example; do
  [ -f "$f" ] && pass "$f exists" || fail "$f is missing"
done
if [ -f CLAUDE.md ]; then
  for h in '## What this is' '## Words used here' '## Environments' '## Rules that are never broken' '## Owner decisions' '## Known state'; do
    grep -q "^$h" CLAUDE.md && pass "CLAUDE.md has: $h" || fail "CLAUDE.md is missing the section: $h"
  done
  grep -q 'FILL IN' CLAUDE.md && fail "CLAUDE.md still has FILL IN markers" || pass "CLAUDE.md has no FILL IN markers"
  grep -q 'NOT READY' CLAUDE.md && warn "CLAUDE.md says an environment is NOT READY"
fi
if [ -f AGENTS.md ]; then
  grep -q 'CLAUDE.md' AGENTS.md && grep -q 'SESSIONS.md' AGENTS.md \
    && pass "AGENTS.md points to CLAUDE.md and SESSIONS.md" \
    || fail "AGENTS.md must point to CLAUDE.md and SESSIONS.md"
fi
if [ -f SESSIONS.md ]; then
  grep -qE '^## Session [0-9]+: 20[0-9][0-9]-' SESSIONS.md \
    && pass "SESSIONS.md has a dated entry" \
    || fail "SESSIONS.md has no dated entry yet"
fi

echo "--- Secrets"
for f in .env .env.local .env.production private-data/x; do
  git check-ignore -q "$f" && pass "git ignores $f" || fail "git does not ignore $f"
done
git check-ignore -q .env.example && fail "git ignores .env.example, but it should be committed" || pass ".env.example can be committed"
secret_files='(^|/)(\.env(\..+)?|.+\.pem|.+\.key|.+\.p12|.+\.pfx|id_rsa|id_ed25519|credentials\.json|service-account.*\.json)$'
tracked=$(git ls-files | grep -E "$secret_files" | grep -vE '(^|/)\.env\.example$')
[ -z "$tracked" ] && pass "no secret files are in git" || fail "secret files are in git: $tracked"
if command -v gitleaks >/dev/null 2>&1; then
  if gitleaks git --redact --no-banner . >/dev/null 2>&1; then
    pass "gitleaks found no secrets in the git history"
  else
    fail "gitleaks found a possible secret in the git history. Run: gitleaks git --redact --no-banner --verbose ."
  fi
else
  fail "gitleaks is not installed"
fi

echo "--- Keeping AI tools out of secrets"
grep -q 'env' .claude/settings.json 2>/dev/null && pass ".claude/settings.json blocks .env" || fail ".claude/settings.json is missing or does not block .env"
[ -f .cursorignore ] && pass ".cursorignore exists" || fail ".cursorignore is missing"

echo "--- Guard rails"
[ "$(git config core.hooksPath)" = ".githooks" ] && pass "safety hooks are on" || fail "safety hooks are off. Run: sh scripts/setup-dev.sh"
for f in .githooks/pre-commit .githooks/pre-push scripts/setup-dev.sh scripts/check-setup.sh scripts/protect-main.sh; do
  [ -f "$f" ] && pass "$f exists" || fail "$f is missing"
done
[ -f .github/workflows/checks.yml ] && pass "GitHub checks file exists" || fail ".github/workflows/checks.yml is missing"

echo "--- GitHub"
if git remote get-url origin >/dev/null 2>&1; then
  heads=$(git ls-remote --heads origin main master testing 2>/dev/null)
  echo "$heads" | grep -qE 'refs/heads/(main|master)$' && pass "main is on GitHub" || fail "main is not on GitHub"
  echo "$heads" | grep -q 'refs/heads/testing$' && pass "testing is on GitHub" || fail "testing is not on GitHub"
  default=$(git ls-remote --symref origin HEAD 2>/dev/null | sed -n 's|^ref: refs/heads/\(.*\)[[:space:]]HEAD$|\1|p')
  [ "$default" = "testing" ] && pass "GitHub default branch is testing" || fail "GitHub default branch is '$default', not testing"
else
  fail "this repo has no origin remote"
fi
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null)
  if [ -n "$repo" ]; then
    [ "$(gh repo view --json isPrivate --jq .isPrivate)" = "true" ] && pass "repo is private" || warn "repo is NOT private"
    if gh api "repos/$repo/branches/main/protection" >/dev/null 2>&1; then
      pass "GitHub hard-protects main"
    else
      warn "GitHub does not hard-protect main (a free plan cannot on a private repo). The hooks and checks still apply."
    fi
    result=$(gh run list --branch testing --limit 1 --json conclusion --jq '.[0].conclusion' 2>/dev/null)
    [ "$result" = "success" ] && pass "latest GitHub checks on testing passed" || warn "latest GitHub checks on testing: ${result:-no run yet}"
  fi
else
  warn "gh is not available, so repo privacy, protection and check results were not tested"
fi

if [ "$1" = "--prove" ]; then
  echo "--- Trying to break the rules in a throwaway copy"
  tmp=$(mktemp -d) || exit 1
  trap 'rm -rf "$tmp"' EXIT
  git init -q --bare "$tmp/remote.git"
  git clone -q "$root" "$tmp/copy" 2>/dev/null
  rm -rf "$tmp/copy/.githooks"
  cp -R "$root/.githooks" "$tmp/copy/.githooks"
  cd "$tmp/copy" || exit 1
  git remote set-url origin "$tmp/remote.git"
  git config user.name "setup check"
  git config user.email "setup-check@example.invalid"
  git config core.hooksPath .githooks
  git switch -q -c prove-testing

  tryfail() { # label, then the command that must be refused
    label=$1; shift
    if "$@" >/dev/null 2>&1; then fail "NOT blocked: $label"; else pass "blocked: $label"; fi
  }

  git branch -q -f main HEAD 2>/dev/null
  git switch -q main 2>/dev/null
  echo x > prove-main.txt && git add prove-main.txt
  tryfail "a commit on main" git commit -q -m "should be blocked"
  git reset -q && rm -f prove-main.txt
  git switch -q prove-testing

  token="ghp_$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | head -c 36)"
  printf 'token = "%s"\n' "$token" > prove-secret.txt && git add prove-secret.txt
  tryfail "a commit containing a fake GitHub token" git commit -q -m "should be blocked"
  git reset -q && rm -f prove-secret.txt

  echo "FAKE=1" > .env && git add -f .env
  tryfail "a commit containing a .env file" git commit -q -m "should be blocked"
  git reset -q && rm -f .env

  echo ok > prove-clean.txt && git add prove-clean.txt
  if git commit -q -m "clean commit" >/dev/null 2>&1; then pass "a clean commit is allowed"; else fail "a clean commit was refused"; fi
  tryfail "a push to main" git push -q origin HEAD:refs/heads/main
  if git push -q origin HEAD:refs/heads/testing >/dev/null 2>&1; then pass "a push to testing is allowed"; else fail "a push to testing was refused"; fi
  cd "$root" || exit 1
fi

echo
echo "RESULT: $fails failed, $warns warnings."
[ "$fails" -eq 0 ]
