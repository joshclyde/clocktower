# Clocktower

iOS + watchOS app (with iOS widget and watchOS complication). The Xcode project is generated from `project.yml` with XcodeGen; see `DEV_WORKFLOW.md`.

## Workflow

- Always open a pull request for your changes once they're pushed.

### Large changes: stacked PRs

Split any large change (more than ~300 changed lines, or several separate concerns) into a [stack of PRs](https://docs.github.com/en/pull-requests/get-started/about-stacked-prs) that the user reviews and merges one at a time:

1. Split the work into ordered layers. Each layer covers one concern and builds and passes tests on its own.
2. Branch each layer from the one below it: `<name>-1-<slug>`, `<name>-2-<slug>`, …
3. The bottom PR targets `main`. Every other PR targets **the branch of the PR below it**, so each diff shows only its own layer. There is no separate feature branch or project PR.
4. If the [`gh stack`](https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands) extension is available (`gh extension install github/gh-stack`), create the stack with `gh stack init` / `add` / `submit`, or link existing PRs with `gh stack link`. Otherwise, set the PR bases by hand as in step 3.
5. Title each PR `[<name> n/N] …`. In each body, name the PR below and the PR above it.
6. The user merges from the bottom up. Once the bottom PR merges, the next PR is retargeted onto `main`. GitHub does this automatically for linked stacks; otherwise, retarget it yourself and merge `main` into it.
7. Commit review fixes to that layer's branch, then carry them up the stack with `gh stack rebase --upstack`, or by merging the fixed branch into each layer above it.
