---
name: gh-pr-review-fix
description: Reads GitHub PR review feedback (structured top-level reviews with P1/P2/P3 items, inline review threads, human collaborator or AI reviewer comments), verifies claims against the codebase, implements minimal fixes with automated regression tests, replies and resolves threads, and verifies CI checks. Use when addressing PR review comments or closing review feedback loops.
---

# gh-pr-review-fix

## Goal

Turn open GitHub pull request review feedback into verified, regression-tested code changes, close the feedback loop on GitHub (by resolving inline review threads or posting a structured top-level resolution comment with commit SHAs), and verify that all CI status checks pass.

## Principles

- **Verify before implementing**: Treat all reviewers (human collaborators or AI reviewers) with the same engineering rigor. Check every suggestion against codebase facts, architecture, and invariants. Do not blindly adopt suggestions that break contracts or hallucinate APIs; push back factually in the reply when feedback is invalid or out of scope.
- **Lock in regression tests**: Any bug or edge case reported in review must be backed by automated test coverage before considering it resolved.
- **Respect repository workflow rules**: Check the repository for developer guidelines (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`). Respect git worktree requirements, branch naming, commit message conventions (e.g., `emoji [scope] description`), trailer restrictions, and file size limits.
- **Close the loop**: Commit, push to the PR branch, reply with concise technical notes linking the commit SHA, resolve conversations, and watch CI checks until green.

## Workflow

Copy and track progress:

```
PR review fixes:
- [ ] 1. Identify PR, head branch, and repository workflow rules (worktree, commit format)
- [ ] 2. Fetch all review feedback: top-level reviews and unresolved inline threads
- [ ] 3. Itemize & verify: dissect into concrete issues (P1/P2/P3), map root causes, verify codebase facts
- [ ] 4. Implement minimal fixes and add automated regression test coverage
- [ ] 5. Run test suites and linters locally (zero regressions)
- [ ] 6. Commit and push adhering to repo conventions
- [ ] 7. Reply on GitHub (inline thread reply + resolution, or top-level PR summary comment)
- [ ] 8. Monitor CI checks until green (gh pr checks --watch)
- [ ] 9. Clean up temporary worktree or branch if applicable
```

---

### Step 1: Identify the PR & Repository Guidelines

Check PR status and metadata:

```bash
gh pr view <number> --json number,title,headRefName,baseRefName,url
```

Check repository workflow rules:
- Inspect `AGENTS.md`, `CLAUDE.md`, or `CONTRIBUTING.md` at repo root.
- **Worktree workflow**: If the repository mandates worktree usage (e.g., `.worktree/<branch>`):
  ```bash
  git worktree add .worktree/<branch-name> <headRefName>
  cd .worktree/<branch-name>
  ```
  Otherwise, check out the PR head branch directly:
  ```bash
  gh pr checkout <number>
  ```

---

### Step 2: Fetch Review Feedback

GitHub PR feedback typically comes in two forms: **Top-level structured reviews** and **Inline diff threads**. Fetch both to get the complete picture.

#### 2.1 Top-level Reviews & Conversation Comments

Human collaborators and structured reviewers often submit reviews containing markdown blocks, prioritization (e.g. `### P1`, `### P2`), and high-level architectural feedback:

```bash
gh pr view <number> --json reviews,comments
```

For a human-readable thread view in terminal:

```bash
gh pr view <number> --comments
```

> [!NOTE]
> Do NOT use `gh pr view --json reviewThreads`; `reviewThreads` is not a recognized field in `gh pr view` and will throw an error. Use GraphQL below for inline threads.

#### 2.2 Inline Review Threads (GraphQL)

To inspect line-by-line unresolved review threads:

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $n: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $n) {
      reviewThreads(first: 100) {
        totalCount
        nodes {
          id
          isResolved
          path
          line
          comments(first: 5) {
            nodes {
              id
              body
              author { login }
            }
          }
        }
      }
    }
  }
}' -f owner='OWNER' -f repo='REPO' -f n=PR_NUMBER
```

Filter for threads where `isResolved == false`.

---

### Step 3: Itemize, Verify & Implement

1. **Itemize feedback**: Group issues by priority or concern (e.g., P1 / P2 / P3 or File A / File B).
2. **Verify against codebase**:
   - Inspect the cited file ranges and related caller modules.
   - Determine if the critique is factually correct.
   - If incorrect or harmful: formulate a factual, polite decline with technical reasoning.
3. **Implement minimal fix**:
   - Make precise, localized edits avoiding speculative churn.
   - Avoid breaking existing tests or contracts.
4. **Add regression tests**:
   - Write automated unit/integration tests that specifically exercise the scenario identified by the reviewer.
5. **Local verification**:
   - Run the repository's type checks, linters, and test suites (e.g. `nsh check app`, `nsh test app`, `cargo test`, `npm test`, etc.).
   - Verify that all existing and new tests pass with zero errors.

---

### Step 4: Commit & Push

- Follow repository commit title conventions (e.g., `emoji [scope] The main change`).
- Do not include agent trailers (`Co-Authored-By: Claude`, Cursor, etc.) unless requested by the user.
- Push the commit to the PR head branch:
  ```bash
  git push origin <headRefName>
  ```

---

### Step 5: Reply, Resolve & CI Loop

#### 5.1 When Addressing Inline Review Threads

1. **Reply to the comment** (REST):
   ```bash
   gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies -f body="Fixed in <commit-sha>: <short description of fix and regression test>."
   ```
   *(Note: `comment_id` must be the top comment of that thread).*

2. **Resolve the thread** (GraphQL):
   ```bash
   gh api graphql -f query='
   mutation($id: ID!) {
     resolveReviewThread(input: { threadId: $id }) {
       thread { isResolved }
     }
   }' -f id='THREAD_NODE_ID'
   ```

#### 5.2 When Addressing Top-level / Batch Reviews

If feedback was delivered as a top-level review or batch comment without individual inline thread IDs, post a structured summary comment on the PR:

```bash
gh pr comment <number> -b "Addressed review feedback in \`<commit-sha>\`:

- **P1 (<Issue Summary>)**: <Root cause> → <What was changed>.
- **P2 (<Issue Summary>)**: <Root cause> → <What was changed>.
- **Regression test coverage**: <Summary of new automated test cases added>.
"
```

#### 5.3 Monitor CI Checks

Wait for and verify that all CI status checks run and pass on the latest head commit:

```bash
gh pr checks <number> --watch
```

Ensure all required checks are green. If any check fails, inspect logs immediately and apply a fix before completing.

#### 5.4 Clean Up Worktree

If a git worktree was created in Step 1, remove it once the branch is pushed:

```bash
git worktree remove .worktree/<branch-name>
```

---

## Reply Text Examples

### Adopting a Suggestion
> Fixed in `4558ae5`: Scoped keyboard actions to frontmost surface when modal is open and added regression tests in `shortcuts.test.tsx`. Resolving thread.

### Declining a Suggestion (with Technical Evidence)
> Not adopting: `LibraryView` state is preserved deliberately across tab switches to maintain smooth list restoration. Re-mounting would cause thumbnail image reload flicker. Happy to adjust if you have a different transition requirement.

---

## Edge Cases

| Situation | Action |
| :--- | :--- |
| Suggestion is factually invalid | Reply explaining the technical contradiction or architecture constraint. Do not resolve unless agreed. |
| Duplicate feedback across multiple lines | Fix once; reply on the primary comment referencing the fix commit, and resolve related threads. |
| Top-level review with no inline threads | Reply with a structured batch comment via `gh pr comment <number> -b "..."`. |
| PR head branch is out of date with `main` | Check if repo prefers rebase or merge; test merge tree before pushing. |
| Local worktree required by repo | Always work within `.worktree/` and remove immediately after pushing. |
