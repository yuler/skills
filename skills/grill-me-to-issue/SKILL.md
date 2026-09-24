---
name: grill-me-to-issue
description: >-
  Call Matt Pocock's /grill-me skill, settle the feature spec in that
  interview, then file it as a GitHub issue with the grill-me and spec labels
  so a later agent can implement it. Use when the user wants to grill a plan
  into an issue, or names grill-me-to-issue. Do not implement the feature.
disable-model-invocation: true
---

# grill-me-to-issue

Turn a feature idea into an implementation spec on GitHub. Do the interview first. File the issue second. Do not write the feature.

A later agent should be able to implement the work from the issue alone, without this conversation.

## Workflow

1. Run Matt Pocock's **/grill-me** skill to completion. Do not draft the issue, edit the repo, or start implementation during the interview.
2. When that interview reaches a shared understanding, restate the full spec in the conversation and wait for the user to confirm it.
3. After that confirmation, create one GitHub issue with `gh issue create`. Write the issue in English. The issue body is the spec. Auto-assign the labels below.
4. Reply with the issue URL and stop. Do not implement the spec.

If the user only wants the interview, they should use Matt Pocock's `/grill-me`. This skill ends at the issue.

## grill-me

The interview is Matt Pocock's `/grill-me` skill, not a summary of it. Read that skill and follow it for the whole interview. It runs a `/grilling` session: one decision at a time, each with a recommended answer, facts looked up instead of asked, and no action until the user confirms the shared understanding.

## Issue

The issue is the spec a later agent will build. Create it in English. Title and body are English even when the conversation was not.

Before writing the title, read recent issues in the current repo (`gh issue list`) and match that repo's title style.

The body must contain:

- What to build, including the decisions made in the interview
- Constraints and the commands, paths, or interfaces that are already chosen
- Out of scope
- A test plan, as checkboxes, that covers the agreed behavior

Do not leave choices open that the interview already closed. Do not add work the user did not accept.

Create the issue in the current repo with `gh issue create`. Show the URL when it exists.

### Labels

Auto-assign these labels on every issue this skill creates:

| Label      | Meaning                                                    |
| ---------- | ---------------------------------------------------------- |
| `grill-me` | The spec was settled with Matt Pocock's `/grill-me` skill |
| `spec`     | The issue is an implementation spec for a later agent     |

List labels with `gh label list`. Create any of these that are missing, then pass both to `gh issue create --label`. Do not skip them because they were absent.

```bash
gh label create "grill-me" --color "B60205" --description "Spec settled with Matt Pocock's /grill-me"
gh label create "spec" --color "0052CC" --description "Implementation spec for a later agent"
```

If the user named extra labels during the interview, create any that are missing and assign those too. Do not add `enhancement`, `bug`, or `documentation` unless the user asked for that label.

## Stop

After the issue exists, stop. Do not implement the feature, open a branch, or open a pull request unless the user asks for that in a later turn.
