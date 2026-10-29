# Clocktower

iOS + watchOS app (with iOS widget and watchOS complication). The Xcode project is generated from `project.yml` with XcodeGen; see `DEV_WORKFLOW.md`.

## Workflow

- Always open a pull request for your changes once they're pushed.
- Keep history linear: the repo allows only squash and rebase merging. A single PR into `main` is squash-merged. To bring in changes from `main` or another branch, rebase onto it and force-push (`--force-with-lease`); never merge it in.

### Large changes: stacked PRs on a feature branch

Split any large change (more than ~300 changed lines, or several separate concerns) into a stack of small PRs the user reviews and merges one at a time. Use plain branches and PR bases, not GitHub's official stacked-PR feature or `gh stack`.

1. Create `feature/<name>` from `main` and push it.
2. Split the work into ordered layers. Each layer covers one concern and builds and passes tests on its own.
3. Branch each layer from the one below it, starting from `feature/<name>`: `feature/<name>-1-<slug>`, `feature/<name>-2-<slug>`, …
4. The bottom PR targets `feature/<name>`. Every other PR targets **the branch of the PR below it**, so each diff shows only its own layer.
5. Title each PR `[<name> n/N] …`. In each body, list the whole stack and mark the PRs below and above it.
6. The user **squash-merges** layers from the bottom up, so each layer lands on `feature/<name>` as one commit. The repo has **Automatically delete head branches** turned on, so merging a layer deletes its branch, and GitHub retargets the next PR onto `feature/<name>`. Then rebase the open layers onto `feature/<name>` (step 10): until you do, the next PR's diff also shows the merged layer, because the squash commit replaced its original commits.
7. Once the first layer has merged (GitHub can't open a PR with no changes), open `feature/<name>` → `main` as the project PR. It summarizes the whole change and lists the stack. The user merges it last with **rebase and merge**, so `main` gets one commit per layer. If `main` moves in the meantime, rebase `feature/<name>` onto `main`, force-push it, and then rebase the open layers (step 10).
8. Add review fixes as new commits on that layer's branch rather than amending, so the reviewer sees just the fix (the squash merge folds them in anyway). Then rebase the layers above it (step 10).
9. If a PR still targets a merged branch, retarget it to `feature/<name>` yourself.
10. To rebase the stack, check out every open layer as a local branch, then from the top layer run one `git rebase --update-refs`, which moves all the layers below it too. Force-push each moved branch with `git push --force-with-lease origin <branch>…`. Each layer's own diff stays the same, so earlier reviews still apply.
    - After a layer merges: `git rebase --update-refs --onto origin/feature/<name> <old>`, where `<old>` is the merged layer's last commit (its PR's head commit).
    - After `feature/<name>` is rebased onto `main`: the same, with `<old>` being the tip of `feature/<name>` before that rebase.
    - After a review fix on layer n: `git rebase --update-refs feature/<name>-n-<slug>`.
