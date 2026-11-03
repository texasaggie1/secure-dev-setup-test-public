# AGENTS.md: Sample

Codex, Cursor and other AI tools load this file automatically. The full instructions are in CLAUDE.md.

**Before you do anything:** read CLAUDE.md all the way through, then the top 3 entries of SESSIONS.md. If you cannot read them, STOP and say so.

Hard rules, in case you read nothing else:

1. Never commit to `main` and never push to `main`. All work lands on `testing` first.
2. Merge to `main` only after Pat gives a clear yes for that exact change.
3. No secrets in git, in chat, or in logs. Use environment variables. Never ask a person to paste a secret to you.
4. The testing environment never touches production data or production keys.
5. Never use `--force`, `--no-verify`, `git reset --hard` or `git clean`. Never delete data.
6. Do only what was asked. If you are unsure, or a fix fails twice, STOP and ask.
7. Before you stop, add an entry to the top of SESSIONS.md, then commit and push it. Work that is not pushed does not exist for the next AI.
