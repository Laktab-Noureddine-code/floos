# Project rules

- Never add Claude/AI attribution (e.g. `Co-Authored-By: Claude`, "Generated with Claude Code") to commit messages, PR descriptions or any git metadata.
- Work and push on `main` only (remote: https://github.com/Laktab-Noureddine-code/floos.git). No feature branches on the remote.
- Resume work from `STATUS.md`; specs live in `specs/001-floos-finance-app/`; constitution in `.specify/memory/constitution.md`.
- UI is French only; add strings with `python3 tool/arb_add.py` then `flutter gen-l10n`.
