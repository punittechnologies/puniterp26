## Requested change

Describe the exact requested behavior and the affected web/app screens.

## Existing behavior preserved

List the existing workflows inspected and confirmed unchanged.

## Safety checklist

- [ ] I started from the latest `origin/main` on a task branch.
- [ ] I read `AGENTS.md` and `docs/PROTECTED_FEATURE_BASELINE.md`.
- [ ] The change is additive or narrowly scoped.
- [ ] No existing route, menu, field, filter, report, import/export function,
      printer element, API field, or permission was removed.
- [ ] Existing tenant/account isolation remains intact.
- [ ] Existing saved label templates and classic APK behavior remain compatible,
      when applicable.
- [ ] I added regression coverage for new and preserved behavior.
- [ ] `scripts/verify-protected-features.sh` passes.
- [ ] Web tests/build pass, when applicable.
- [ ] Flutter analysis/tests pass, when applicable.
- [ ] I reviewed the complete diff for accidental deletions.
- [ ] No secrets, `.env`, keystores, dependencies, APK intermediates, caches, or
      generated build folders are included.

## Test evidence

Paste the commands run and their results.

## Deployment and rollback

State whether deployment is required, which files change, and how to roll back.
