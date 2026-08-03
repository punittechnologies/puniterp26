# Employee Codex Start Prompt

Paste this at the beginning of every new development task, followed by the
specific requested change:

```text
Work from the latest origin/main in the punittechnologies/puniterp26
repository. Read the complete AGENTS.md and
docs/PROTECTED_FEATURE_BASELINE.md before making changes.

First inspect git status, current branch, recent commits, relevant source,
existing tests, routes, and the complete existing workflow being changed.
Create a new task branch; do not work directly on main.

Preserve every existing feature. Do not remove, rename, hide, replace, or
simplify any existing menu, page, route, field, filter, report, import/export
function, API response field, role permission, database field, label element,
printer behavior, classic APK behavior, or tenant-isolation behavior unless my
task explicitly requests that exact removal.

Make the smallest additive change. Add regression tests covering the new
behavior and the existing behavior that must remain. Run
scripts/verify-protected-features.sh and all relevant web/Flutter tests and
build checks. Review the complete git diff for accidental deletions.

Do not deploy, merge to main, push directly to main, modify production data, or
use production credentials. Commit only to the task branch and give me the
branch name, commit, tests, affected files, risks, and exact deployment plan
for approval.

Specific task:
[WRITE THE REQUEST HERE]
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
