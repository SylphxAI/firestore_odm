# firestore_odm — local agent notes only

Doctrine and fleet delivery law live in the **host always-on constitution**
(`~/.grok/AGENTS.md` / Doctrine template). This file must **not** restate,
weaken, or fork that law (including PR-vs-direct-trunk delivery).

Local truth: `PROJECT.md`, `.doctrine/project.json` when present.

## Boundary hazards

- Never commit secrets, tokens, `.env` files, or credentials.

## Local commands

- See `PROJECT.md` / `README.md` for repo validation commands.

## Validation notes

- Prefer the **narrowest** affected check before full workspace runs.
- Report layers honestly: local diff · trunk FF · deploy · prod proof (do not collapse).
