# Clocktower

iOS + watchOS app (with iOS widget and watchOS complication). The Xcode project is generated from `project.yml` with XcodeGen; see `DEV_WORKFLOW.md`.

## Workflow

- Always open a pull request for your changes once they're pushed.

### Large changes: stacked PRs into a feature branch

Split any large change (more than ~300 changed lines, or several separate concerns) into small PRs the user can review one at a time:

1. Create `feature/<name>` from `main` and push it.
2. Split the work into ordered sub-PRs. Each covers one concern and builds and passes tests on its own. Branch each one from the previous one (`feature/<name>-1-<slug>`, `feature/<name>-2-<slug>`, …) and open every sub-PR **against `feature/<name>`**.
3. Title sub-PRs `[<name> 1/N] …`. In each body, say which PR must merge before it.
4. Once the first sub-PR is merged (GitHub needs a commit to diff), open `feature/<name>` → `main` as the project PR. It summarizes the whole change and lists the sub-PRs in merge order.
5. The user merges sub-PRs in order with **merge commits** (not squash or rebase), so each later PR's diff shrinks to just its own changes. They merge the project PR last.
6. Push review fixes to that sub-PR's branch, then merge that branch into the later sub-branches.
