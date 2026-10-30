# Clocktower

iOS + watchOS app (with iOS widget and watchOS complication). The Xcode project is generated from `project.yml` with XcodeGen; see `DEV_WORKFLOW.md`.

## Conventions

Follow `docs/CONVENTIONS.md`. Read its **Saved data** section before adding, removing or renaming anything in `ChimeSettings` or a type inside it: a field that fails to decode resets every setting.

## Workflow

- Always open a pull request for your changes once they're pushed.
- Never force-push and never rewrite pushed history (no rebase, amend or squash of pushed commits). Add changes as new commits.
- To bring in changes from `main` or another branch, merge it in with a merge commit (`git merge`), then push normally.
- Everything lands on `main` as a single commit: a PR into `main` is **squash-merged**.

### Large changes: stacked PRs on a feature branch

Split any large change (more than ~300 changed lines, or several separate concerns) into a stack of small PRs the user reviews and merges one at a time. Use plain branches and PR bases, not GitHub's official stacked-PR feature or `gh stack`.

1. Create `feature/<name>` from `main` and push it.
2. Split the work into ordered layers. Each layer covers one concern and builds and passes tests on its own.
3. Branch each layer from the one below it, starting from `feature/<name>`: `feature/<name>-1-<slug>`, `feature/<name>-2-<slug>`, …
4. The bottom PR targets `feature/<name>`. Every other PR targets **the branch of the PR below it**, so each diff shows only its own layer.
5. Title each PR `[<name> n/N] …`. In each body, list the whole stack and mark the PRs below and above it.
6. The user merges layers from the bottom up with a **merge commit**, so each layer's commits land on `feature/<name>` unchanged. The repo has **Automatically delete head branches** turned on, so merging a layer deletes its branch, and GitHub retargets the next PR onto `feature/<name>`. Because the merged commits are the same ones the next layer is built on, its diff still shows only its own layer; nothing needs to be rebased.
7. Once the first layer has merged (GitHub can't open a PR with no changes), open `feature/<name>` → `main` as the project PR. It summarizes the whole change and lists the stack. The user merges it last with **squash and merge**, so the whole feature lands on `main` as one commit.
8. Add review fixes as new commits on that layer's branch, then carry them up the stack (step 10).
9. If a PR still targets a merged branch, retarget it to `feature/<name>` yourself.
10. To carry changes up the stack, merge each branch into the one above it, from the bottom up, and push each with a normal `git push`:
    - After a review fix on layer n: merge layer n into layer n+1, then layer n+1 into n+2, and so on to the top.
    - If `main` moves: merge `main` into `feature/<name>`, then merge `feature/<name>` into the lowest open layer and carry it up the same way.
