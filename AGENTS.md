# Punit ERP Development Rules

These instructions apply to every Codex session and every contributor working in
this repository.

## Source of truth

- `origin/main` is the approved production source baseline.
- Web code is in `apps/platform`.
- Android/Flutter code is in `apps/tablet`.
- Never reconstruct the project from screenshots, an APK, an old folder, or a
  partial Hostinger download when the GitHub repository is available.
- Before editing, run `git status`, `git branch --show-current`,
  `git log -10 --oneline`, and inspect the relevant existing implementation.
- Preserve unrelated modified and untracked files. Never overwrite another
  contributor's work.

## Mandatory compatibility rule

Existing behavior is protected. Changes must be additive or narrowly scoped.

- Do not delete, rename, hide, replace, or simplify an existing page, route,
  menu item, form field, filter, report, import/export workflow, API field,
  printer command, database column, or user role unless the owner explicitly
  requests that exact removal.
- Do not replace a complete existing module with a smaller implementation.
- Do not remove old behavior merely because a new workflow is being added.
- New optional features must default to off or preserve the previous default.
- Database migrations must be additive and reversible. Do not drop or rename
  production data without explicit approval and a migration plan.
- Existing saved label templates and the classic APK printing path must remain
  compatible when Web Label features are changed.
- Tenant/account data must remain isolated across login, logout, and account
  switching.

Read `docs/PROTECTED_FEATURE_BASELINE.md` before changing application behavior.
Also read `docs/SYSTEM_FEATURE_CATALOG.md` for the complete web, API, Android,
printing, reporting, security, and deployment map.
If the requested change conflicts with that baseline, stop and explain the
conflict before editing.

A task prompt authorizes only the feature named in that task. It does not
authorize collateral changes. If completing a task appears to require removing,
replacing, or changing an unrelated protected workflow, stop and obtain an
explicit owner decision before proceeding.

Employees should start new Codex work with the prompt in
`docs/EMPLOYEE_CODEX_START_PROMPT.md`.

The protection files themselves are owner-controlled. An employee or agent must
not modify `AGENTS.md`, `docs/PROTECTED_FEATURE_BASELINE.md`,
`scripts/verify-protected-features.sh`, the pull-request template, or the
regression workflow merely to make a failing check pass. Any baseline change
requires an explicit owner request and must be isolated in its own reviewed
commit.

## Required workflow

1. Fetch `origin` and start from the latest `origin/main`.
2. Create a task branch. Do not develop directly on `main`.
3. Write down the exact files and existing workflows that may be affected.
   Include direct consumers (web, API, classic APK, Web Label APK, database,
   reports, imports/exports, and deployment) and mark each as changed or
   explicitly unchanged.
4. Make the smallest change that satisfies the request.
5. Add or update regression tests for both the new behavior and preserved old
   behavior.
6. Run `scripts/verify-protected-features.sh`.
7. Run the applicable web and Flutter checks below.
8. Review `git diff` for accidental deletions and unrelated changes.
   A large rewrite is not acceptable when a narrow patch can satisfy the task.
9. Open a pull request using the repository template.
10. Merge or deploy only after owner approval. Never force-push.

## Validation commands

For web changes:

```bash
cd apps/platform
./vendor/bin/pint --dirty
npm run build
php artisan test
php artisan view:cache
php artisan view:clear
```

For Flutter/Android changes:

```bash
cd apps/tablet
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

For production Web Label APKs, use the existing release keystore and Web Label
flavor. Never substitute a debug signature and never commit signing secrets.

## Deployment rules

- GitHub `main` must contain the reviewed source before production deployment.
- Deploy only the intended files from the reviewed commit.
- Do not edit production application code directly in hPanel.
- Do not run destructive database or filesystem commands during deployment.
- Verify `/up`, `/login`, and changed public assets after web deployment.
- Keep a rollback artifact for changed production files.
- Never commit `.env`, credentials, keystores, dependency folders, build
  directories, caches, APK build intermediates, or generated secrets.
