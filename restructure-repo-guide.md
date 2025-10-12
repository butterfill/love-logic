# Repository Restructure and Cleanup Guide

Audience: Maintainers and consumers of the love-logic project (including downstream apps that use the generated browser bundle). This guide is self-contained and explains why and how to clean up the repository safely, with a focus on identifying and mitigating risks for a long-lived, widely used codebase.

Context summary
- The active project lives in `love-logic_new_project/`.
- Root-level files and folders appear to be legacy or exploratory, with one optional component used by the browser bundle build:
  - Safe-to-delete candidates (pending verification): `README.md` (root), `_project.yaml`, `logic.html`, `logic.komodoproject`, `logic_notes.coffee`, `substitute.js`, `truth_tables.js`, `doc_dox/`, `docs/` (root), `parse/`, `specifications/`, `lib/`.
  - Conditionally keep: `ui_components/`. It is only used by the optional browser bundle entry `love-logic_new_project/_browserify/awfol.browserifyme.coffee` (requires `../../ui_components/tree_proof/tree`).
- Consumers reportedly use only the generated browser bundle (e.g., `awfol.bundle.js`). If true, moving or removing UI sources does not affect them so long as the bundle remains API/filename-compatible.

Goals
1) Reduce clutter by removing legacy files not used by the current project.
2) Consolidate optional UI components under `love-logic_new_project/` for clarity.
3) Preserve compatibility for downstream applications that already rely on the generated bundle.
4) Provide a safe, auditable process with rollback.

High-level plan
- Phase 0: Inventory and backups.
- Phase 1: Verification (prove what’s unused; confirm how downstreams consume the code).
- Phase 2: Optional internal move of `ui_components/` and path updates.
- Phase 3: Cleanup of legacy files.
- Phase 4: Validate, release, and communicate.
- Phase 5: Monitor and, if needed, roll back.

Risks and mitigations
- Risk: Hidden downstream references to root paths (e.g., `ui_components/` or other legacy files).
  - Mitigation: Organization-wide search (code search, GitHub search) for repo-relative paths such as `ui_components/tree_proof/tree`, `substitute.js`, `truth_tables.js`, `logic.html`, and raw links to files in this repo.
  - Mitigation: Add a temporary compatibility shim (symlink or stub re-export) if moving `ui_components/`.
- Risk: Consumers rely on static assets (CSS/JS) from `ui_components/` by direct URL.
  - Mitigation: Confirm that consuming apps only load the generated bundle; if any asset is hotlinked, mirror it in the new location and keep an alias at the old path for one release cycle.
- Risk: Bundle build breaks if paths change.
  - Mitigation: Update the require path in `awfol.browserifyme.coffee`, rebuild, test in a browser.
- Risk: Loss of historical docs/specs that are still occasionally referenced.
  - Mitigation: Tag a release before cleanup; archive the old state; optionally move any still-useful docs under a `legacy/` folder.

Phase 0 — Inventory and backups
1) Create a maintenance branch: `git checkout -b chore/restructure-repo`.
2) Tag current state: `git tag -a pre-restructure-<date> -m "Pre-restructure snapshot"` and push tags.
3) Export/backup: Ensure CI artifacts or local builds of `awfol.bundle.js` are backed up if needed.

Phase 1 — Verification
A. Confirm internal references within this repo
- Ensure there are no references from `love-logic_new_project/**` to legacy root files, except the known reference:
  - `love-logic_new_project/_browserify/awfol.browserifyme.coffee` requires `../../ui_components/tree_proof/tree`.
- Sanity-check: search for mentions of legacy items in `love-logic_new_project/**`:
  - `logic.html`, `substitute.js`, `truth_tables.js`, `logic_notes.coffee`, `_project.yaml`, `logic.komodoproject`, `lib/require.js`, `underscore.js`.

B. Confirm how downstreams consume the library
- Verify with maintainers (and/or audit deployment configs) that downstreams import only the generated bundle (`awfol.bundle.js` or similar), not internal source paths.
- If any exception exists (e.g., a teaching site hotlinking `ui_components` CSS/JS directly from this repo), note the path and plan a temporary alias.

Phase 2 — Optional: move `ui_components/` under `love-logic_new_project/`
Why: keep all project sources under one directory; reduce root clutter.
Steps:
1) Move folder: `git mv ui_components love-logic_new_project/ui_components`.
2) Update require path in `love-logic_new_project/_browserify/awfol.browserifyme.coffee`:
   - From: `tree = require('../../ui_components/tree_proof/tree')`
   - To:   `tree = require('../ui_components/tree_proof/tree')`
3) Rebuild the browser bundle per `_browserify/` instructions (e.g., `bash browserify_do.sh` or the documented build steps). Ensure the output filename and global API stay the same so consumers are unaffected.
4) Test in a browser (see Phase 4 tests) to ensure UI still works.

Compatibility options (only if there’s any chance of external references to the old path):
- Symlink: create a root-level symlink `ui_components -> love-logic_new_project/ui_components`.
- Stub re-export: retain a minimal `ui_components` directory at the root with a small `tree_proof/tree.js` that `module.exports = require('../../love-logic_new_project/ui_components/tree_proof/tree')` and a README explaining the move.
- Time-boxed duplicate: keep a duplicate copy for one release, marked deprecated, then remove in the next minor release.

Phase 3 — Remove legacy files and folders (after verification)
Subject to Phase 1 verification and team agreement, remove:
- Files: `README.md` (root), `_project.yaml`, `logic.html`, `logic.komodoproject`, `logic_notes.coffee`, `substitute.js`, `truth_tables.js`.
- Folders: `doc_dox/`, `docs/` (root-level docco output), `parse/`, `specifications/`, `lib/`.
Notes:
- If any content is historically valuable, move it to `legacy/` instead of deleting.
- For `lib/require.js` and `lib/underscore.js`: these are used only by the old `logic.html`; they can be removed if `logic.html` is removed.

Phase 4 — Validation and release
A. Tests and manual checks
- Run unit tests: `npm ci && npm test` inside `love-logic_new_project/`.
- Validate docs (if applicable in the project): `npm run docs:test`.
- Rebuild the browser bundle and smoke-test it:
  - Load an HTML page that includes the rebuilt `awfol.bundle.js`.
  - Verify that the global variables or APIs exposed by the bundle (e.g., `fol`, `proof`, and `tree`) behave as before.
- Optional browser UI test: if you keep the `tree` UI, load a simple proof tree and confirm the layout renders using the included vendor scripts (Treant/Raphael) or however your demo harness is configured.

B. Versioning and changelog
- Bump version (patch or minor) to reflect internal reorg without API changes.
- Update `CHANGELOG.md` with a “Repo restructure” entry:
  - Moved: `ui_components/` to `love-logic_new_project/ui_components/` (no API changes; bundle unchanged).
  - Removed: legacy files and doc outputs (no longer used).
  - Note any temporary shims kept for compatibility and the plan to remove them in a future release.

C. Communication
- Post a short announcement to relevant channels (e.g., Slack, email, README) outlining what changed, what remains the same (bundle path/API), and the rollback plan.

Phase 5 — Monitor and rollback plan
- Monitor error reports and usage metrics where available.
- If any downstream breakage is reported:
  - Quickly restore the old path via symlink or stub (if not already in place).
  - Or revert the branch/merge commit.
  - Publish a hotfix release if needed.

Decision matrix: `ui_components/`
- If all consumers use only the generated browser bundle and do not hotlink UI assets:
  - Move `ui_components/` under `love-logic_new_project/` and update the require path; no external impact expected.
- If any consumers hotlink assets from `ui_components/`:
  - Move, but add a root-level symlink or stub for one release; announce deprecation; remove alias in next release.
- If browser bundle is no longer needed:
  - Consider removing `_browserify/` and `ui_components/` entirely, after confirming no downstreams depend on it.

Checklist (copy/paste)
- [ ] Create branch and tag current state.
- [ ] Verify no internal references to legacy root files from `love-logic_new_project/**` (known exception: `_browserify/awfol.browserifyme.coffee`).
- [ ] Confirm consumption model: downstreams load only the generated bundle.
- [ ] Decide on `ui_components/` strategy (move + update require; symlink/stub if needed).
- [ ] Rebuild bundle; ensure output path/API unchanged.
- [ ] Run tests and manual browser checks.
- [ ] Remove legacy files/folders (or move to `legacy/`).
- [ ] Bump version; update CHANGELOG; communicate changes.
- [ ] Merge the branch; monitor; be ready to roll back or provide temporary aliases if needed.

Appendix: Quick verification commands (examples)
- Search for external-like references within this repo (guards against accidental usage):
  - `git grep -n "ui_components/tree_proof/tree"`
  - `git grep -n "substitute.js\|truth_tables.js\|logic.html\|logic_notes.coffee\|_project.yaml\|logic.komodoproject"`
- If you manage multiple repos, run similar searches across them (e.g., GitHub code search or your org’s code search tooling).

Outcome
Following this guide will:
- Consolidate active code under `love-logic_new_project/`.
- Remove unused legacy files from the root to reduce confusion.
- Preserve the stability of downstream apps consuming the generated browser bundle, with clear mitigations and a rollback plan.
