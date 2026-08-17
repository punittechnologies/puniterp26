# Punit ERP Developer Handoff

This is the practical handoff for the production Laravel web/API and Flutter
Android project. Read it together with `AGENTS.md`,
`docs/PROTECTED_FEATURE_BASELINE.md`, and `docs/SYSTEM_FEATURE_CATALOG.md`.

## Repository and project layout

```text
Repository: https://github.com/punittechnologies/puniterp26
Production baseline: origin/main
Laravel web/API: apps/platform
Flutter Android: apps/tablet
Shared rules and documentation: docs
Regression guard: scripts/verify-protected-features.sh
```

Do not use the legacy `punitdev26/puniterp` repository as the source of truth.
Do not work directly on `main` and never force-push.

## Required first steps for every task

```bash
git fetch origin --prune
git status
git branch --show-current
git log -10 --oneline
git switch -c feature/short-task-name origin/main
```

Then read all repository instructions, inspect the full existing workflow and
tests, and write an impact map before editing. Paste the prompt from
`docs/EMPLOYEE_CODEX_START_PROMPT.md` into every new Codex task.

## Local web/API setup

Requirements are PHP 8.4, Composer, Node.js 22/npm and SQLite or MySQL.

```bash
cd apps/platform
composer install
npm ci
cp .env.example .env
touch database/database.sqlite
php artisan key:generate
php artisan migrate --seed
npm run build
php artisan serve
```

Never copy production secrets into source control. Obtain required development
values through the owner's approved secret-sharing method.

## Local Flutter setup

Use the Flutter version pinned by CI, a Java 17 runtime and Android SDK.

```bash
cd apps/tablet
flutter pub get
flutter analyze
flutter test
```

The installable editions and signed Web Label release process are documented in
`apps/tablet/README.md`. Never replace a production signing key with a new key.

## Application map

The complete protected feature map is in `docs/SYSTEM_FEATURE_CATALOG.md`.
Important implementation areas are:

```text
apps/platform/routes
apps/platform/app/Http/Controllers
apps/platform/app/Livewire
apps/platform/app/Domain
apps/platform/app/Models
apps/platform/resources/views
apps/platform/resources/css
apps/platform/database/migrations
apps/platform/tests
apps/tablet/lib/features
apps/tablet/lib/services/devices
apps/tablet/test
```

Inspect both the producer and every consumer of a field before changing it.
Laravel API changes can affect already-installed APKs even when Flutter code is
not edited.

## Required validation

For every task:

```bash
bash scripts/verify-protected-features.sh
```

For Laravel/web changes:

```bash
cd apps/platform
./vendor/bin/pint --dirty
php artisan test
npm run build
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

Review `git diff --stat`, `git diff`, and `git status` before committing. Do not
commit generated files or unrelated local changes.

## Pull request handoff

The pull request must contain:

1. Exact requested behavior and acceptance criteria.
2. Impact map for web, API, database, Android, printers/scales, reports and
   tenant isolation.
3. Existing workflows inspected and preserved.
4. Files changed and why each file changed.
5. Tests/build commands and results.
6. Migration, compatibility, deployment and rollback notes.
7. Screenshots or device evidence when UI/hardware behavior changes.

Owner approval to develop is not approval to deploy. Deployment is a separate
explicit action.

## Production deployment boundary

Production domain, SSH details, `.env`, database credentials and signing
credentials are intentionally not documented in Git. Obtain them directly from
the owner when deployment is approved.

Before deploying, make a recoverable backup of affected files/data and record
the current production commit. Deploy the reviewed commit only. Typical Laravel
post-deployment commands are:

```bash
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan optimize:clear
php artisan config:cache
php artisan view:cache
php artisan route:cache
```

Verify `/up`, login, the changed workflow and one nearby protected workflow.
Rollback by restoring the recorded application release and applying the
documented migration rollback only when it is safe for production data.
