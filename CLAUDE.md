# CLAUDE.md: Sample

This file is for any AI tool and any new person. It assumes you know nothing about this project. Read all of it. Then read the top 3 entries of SESSIONS.md. Change nothing until you have read both.

## Start of every session

1. Run `git fetch origin`, then `git status -sb`.
2. Run `git switch testing`, then `git pull --ff-only`. If that fails, STOP and tell the human.
3. In a new copy of the repo, run `sh scripts/setup-dev.sh` once.
4. Tell the human where the last session left off and what you plan to do.

## End of every session

1. Add a new entry at the top of SESSIONS.md, using the format described there.
2. If a fact in this file changed, update this file.
3. Commit only the files you changed, by name (`git add path/to/file`). Another AI session may be working in this repo at the same time.
4. Push. Work that is not pushed does not exist for the next AI.

## What to say to your AI (for the human)

- To start: "Read CLAUDE.md and the top of SESSIONS.md, then tell me where we left off."
- To finish: "Wrap up. Update SESSIONS.md, commit and push to testing."
- To go live: "Promote testing to main." The AI will show you what is going live and wait for your yes.

## What this is

done: 3 to 6 plain sentences. What it does, who uses it, why it exists.

## Words used here

| Word | Meaning |
|---|---|
| Production | The real, live system, built from the `main` branch. Real users and real data. |
| Testing | The safe copy, built from the `testing` branch. Fake data only. |
| Promote | Merge `testing` into `main`, which makes the change go live. |
| Secret | Anything that grants access: a password, API key, token, private key, or connection string. |
| done | Add every product name, abbreviation and project word here. |

## How it fits together

done: a simple text diagram of the parts and how they connect.

done: a folder map, one line per folder or file that matters.

## Environments

| | Production | Testing | Local |
|---|---|---|---|
| Git branch | `main` | `testing` | any |
| URL | done | done | done |
| Database (name only) | done | done, never the production one | done |
| Where secrets live | done | done, different values from production | `.env` file, not in git |
| How it deploys | Automatic on merge to `main` | Automatic on push to `testing` | Runs on this computer |
| Real data | Yes | Never | Never |
| Emails, texts, payments | Real | Test mode only, nothing reaches real people | Test mode only |

If an environment is not finished, write NOT READY in its row and say why.

## Commands

Run these from the folder that holds this file.

| Job | Command | What success looks like |
|---|---|---|
| Install | done | done |
| Run locally | done | done |
| Test | done | done |
| Lint | done | done |
| Build | done | done |
| Check the setup | `sh scripts/check-setup.sh` | `0 failed` |

## How work flows

1. Start from `testing`. For a small job, commit on `testing`. For a bigger job or when a tool makes its own branch, branch from `testing` and open a pull request into `testing`.
2. Push. GitHub runs the checks. The testing environment updates by itself.
3. Open the testing URL and try the change yourself. Say exactly what you tried and what happened.
4. Tell the human what changed and how to see it.

**To go live**, only when the human asks:

1. Run `gh pr create --base main --head testing --title "Go live: short summary" --body "plain English list of what changes"`.
2. Wait for the GitHub checks to pass. If a check is red, do not merge. Fix it on `testing`.
3. Show the human the list of changes. Wait for a clear yes from Pat for this exact pull request. A yes for an earlier change does not count.
4. Run `gh pr merge <number> --merge`. Do not use squash or rebase here. They rewrite the commits and leave `testing` and `main` out of step, so every later go-live conflicts.
5. Bring `testing` back in step: `git switch testing`, `git pull --ff-only`, `git fetch origin`, `git merge --no-edit origin/main`, `git push`. If the merge reports a conflict, STOP and tell the human.
6. Open the production URL and confirm the change is live and the site works. Write the result in SESSIONS.md.

**If production breaks after going live:** tell the human at once. Use the host's restore of the previous deploy if it has one (done: exact steps for this host). Then fix the cause with a normal change through `testing`. Do not fix production by hand.

## Database changes

- Every change is a numbered file in the migrations folder (done: path), committed to git. Never change a table by hand.
- Run the migration on the testing database first and prove the testing site still works.
- Before running it on production: take a backup, and get a clear yes from Pat.
- Order matters. Add new columns and tables before the code that uses them goes live. Remove old ones only after no live code uses them.
- Testing data is fake. Never copy production data into testing.

## Rules that are never broken

**Secrets**
- Secrets never go in git, in a committed file, in chat, in a log, or in a screenshot. Environment variables are fine.
- Real values live only in `.env` (ignored by git) or in the hosting provider's settings. `.env.example` lists the names with blank values.
- Never ask a person to paste a secret to you. Tell them the variable name and where to put it.
- Never print a secret. To test that a variable exists, run `grep -c '^NAME=' .env`, which prints a count, not the value.
- Testing and production never share a secret.
- Never skip the hooks with `--no-verify`. If gitleaks blocks a commit, a secret may be involved. Stop and tell the human.
- If a secret reaches git, it is burned, even if you delete it. See "If a secret leaks" below.

**Client and personal data**
- Do not commit client exports, reports, or user lists. Do not commit names, emails, or phone numbers of real people. Do not commit quoted emails or chats. Do not commit anything that helps an attacker more than it helps the next session.
- Those go in `private-data/`, which git ignores. In SESSIONS.md, write one line and point to the file.

**Stop and ask first.** Do not do any of these without a clear yes for that exact action:
- Merge to `main`, or change anything in production.
- Run anything that writes to the production database.
- Delete data, files, or branches you did not create in this session.
- Change sign-in, permissions, billing, DNS, or domain settings.
- Create, rotate, or remove a credential.
- Send a real email, text, or webhook to a real person or system.
- Add a paid service, or a new dependency you cannot explain in one line.
- Change the hooks, the GitHub checks, or these rules.
- Anything you cannot undo.

**Stay on the rails**
- Do only what was asked. If you spot another problem, write it under "Next" in SESSIONS.md. Do not fix it now.
- Do not rewrite working code to suit your own style.
- Do not guess. If you do not know something, say so and find out, or ask.
- Do not reopen a choice listed under "Owner decisions" unless the human brings it up.
- If the same fix fails twice, STOP. Explain what you tried and what you saw.
- Say "done" only for what you ran and saw work. Say "not verified" for everything else.
- Never use `--force`, `git reset --hard`, or `git clean`.

## If a secret leaks

1. Stop normal work. Tell the human now: what kind of secret, which file, which commit. Never show the value.
2. Treat the secret as stolen. Deleting it from git does not make it safe.
3. The human creates a new secret and turns off the old one at the provider. Then they put the new value in `.env` and in the host's settings.
4. Replace the value in the code with an environment variable. Commit that the normal way.
5. Do not rewrite git history unless the human asks. It needs a force push.
6. Add a SESSIONS.md entry: the kind of secret, when it was replaced. No value.
7. If client data or production could be affected, tell Pat right away.

If gitleaks flags something that is not a real secret, show the human. Only after a clear yes, add its fingerprint to `.gitleaksignore`.

## How it works: the parts that are not obvious

done: anything that surprised you, any gotcha that cost time, and why odd-looking code is that way. If there is nothing yet, write "Nothing yet."

## Owner decisions

Dated choices made by the owner. They are settled. Do not reopen them.

- done: YYYY-MM-DD, the choice, who made it, and why.

## Known state and open items

done: what works today, what is unfinished, what is blocked, each with a date. Mark what is verified and what is not.
