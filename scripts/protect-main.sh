#!/bin/sh
# Turns on GitHub's hard protection for main when the plan allows it.
# Safe to run more than once. The result on a free plan is normal, not an error.

command -v gh >/dev/null 2>&1 || { echo "SKIPPED: gh is not installed."; exit 0; }
repo=$(gh repo view --json nameWithOwner --jq .nameWithOwner) || exit 1

# required_approving_review_count is 0 because GitHub does not let a solo
# owner approve their own pull request. A count of 1 would lock them out.
out=$(gh api -X PUT "repos/$repo/branches/main/protection" --input - 2>&1 <<'JSON'
{
  "required_status_checks": {"strict": false, "contexts": ["secret-scan", "build-and-test"]},
  "enforce_admins": true,
  "required_pull_request_reviews": {"required_approving_review_count": 0},
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
)
status=$?

if [ "$status" -eq 0 ]; then
  echo "ON: GitHub now blocks direct pushes to main on $repo."
elif echo "$out" | grep -q 'Upgrade to GitHub Pro'; then
  echo "NOT AVAILABLE: this GitHub plan cannot protect a private repo."
  echo "This is expected. The hooks, the checks and the testing default branch still apply."
else
  echo "FAILED: could not turn on protection for $repo."
  echo "$out"
  exit 1
fi
