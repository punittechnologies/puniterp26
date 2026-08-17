# Employee Codex Start Prompt

Paste this at the beginning of every new development task, followed by the
specific requested change:

```text
Work from the latest origin/main in the punittechnologies/puniterp26
repository. Read the complete AGENTS.md and
docs/PROTECTED_FEATURE_BASELINE.md and docs/SYSTEM_FEATURE_CATALOG.md before
making changes.

First inspect git status, current branch, recent commits, relevant source,
existing tests, routes, and the complete existing workflow being changed.
Create a new task branch; do not work directly on main.

Before editing, provide an impact map listing every web page, API endpoint,
database table/JSON field, Flutter screen, printer/scale workflow, report,
import/export path, permission and tenant boundary that could be affected.
Mark each item as intended to change or required to remain unchanged.

Preserve every existing feature. Do not remove, rename, hide, replace, or
simplify any existing menu, page, route, field, filter, report, import/export
function, API response field, role permission, database field, label element,
printer behavior, classic APK behavior, or tenant-isolation behavior unless my
task explicitly requests that exact removal.

Make the smallest additive change. Add regression tests covering the new
behavior and the existing behavior that must remain. Run
scripts/verify-protected-features.sh and all relevant web/Flutter tests and
build checks. Review the complete git diff for accidental deletions.

The specific task authorizes only that task. It does not authorize cleanup,
redesign, renaming, dependency replacement, schema removal, route removal,
API response changes, or refactoring of nearby working modules. If the task
cannot be completed without one of those actions, stop and ask the owner.

Do not deploy, merge to main, push directly to main, modify production data, or
use production credentials. Commit only to the task branch and give me the
branch name, commit, tests, affected files, risks, and exact deployment plan
for approval.

Do not edit AGENTS.md, the protected feature baseline, the protection script,
pull-request template, or regression workflow to bypass a failing check. Report
the conflict to me instead.

Specific task:
[WRITE THE REQUEST HERE]

Acceptance criteria:
[WRITE THE EXACT EXPECTED RESULT HERE]

Existing workflows that must be regression-tested:
[LIST THE NEARBY WORKFLOWS HERE]
```

## Owner review

Before approving the employee's pull request:

1. Confirm the requested task is clearly written.
2. Read the “Existing behavior preserved” section.
3. Confirm GitHub's regression checks are green.
4. Inspect the “Files changed” tab for deletions or unrelated rewrites.
5. Test the changed workflow and one nearby unchanged workflow.
6. Merge only after those checks. Production deployment remains a separate
   owner-approved action.
