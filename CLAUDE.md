# Clocktower

iOS + watchOS app (with iOS widget and watchOS complication). The Xcode project is generated from `project.yml` with XcodeGen; see `DEV_WORKFLOW.md`.

## Workflow

- Always open a pull request for your changes once they're pushed.

### Large changes: stacked PRs

Split any large change (more than ~300 changed lines, or several separate concerns) into a stack of small PRs the user reviews and merges one at a time. Use plain branches and PR bases, not GitHub's official stacked-PR feature or `gh stack`.

1. Split the work into ordered layers. Each layer covers one concern and builds and passes tests on its own.
2. Branch each layer from the one below it: `<name>-1-<slug>`, `<name>-2-<slug>`, …
3. The bottom PR targets `main`. Every other PR targets **the branch of the PR below it**, so each diff shows only its own layer.
4. Title each PR `[<name> n/N] …`. In each body, list the whole stack and mark the PRs below and above it.
5. The user merges from the bottom up with **merge commits** (not squash or rebase). The repo has **Automatically delete head branches** turned on, so merging a PR deletes its branch, and GitHub retargets the next PR onto `main`.
6. Commit review fixes to that layer's branch, then merge that branch into each layer above it, from the bottom up.
7. If a PR still targets a merged branch, retarget it to `main` yourself.
