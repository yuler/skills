---
name: mail-cli
description: >-
  Send and read mail with the local Himalaya CLI. Use when the user wants to
  send or read email, check an inbox, or grab a signup or verification message
  from a configured Himalaya account.
---

# mail-cli

Send and read mail with the local `himalaya` CLI. Bound accounts stay in the Himalaya config, not in this skill.

## Setup

Before the first read or send in a session, confirm the CLI and the login:

```bash
command -v himalaya
himalaya account list --json
himalaya account check
```

`account list` is the bound accounts: `name`, `default`, and `backends`. Use the default account. When the user names one, pass `-a <name>`.

When `himalaya` is missing, install it and run the check again. When the list is empty or `account check` is not OK, the account is not logged in. Ask the user to finish login with `himalaya` or `himalaya configure`, then re-run `himalaya account check` until it reports OK. Leave existing accounts in place.

## Read

```bash
himalaya envelope list --page-size 10 --json
himalaya envelope search 'subject <pattern>' --json
himalaya message read <id>
```

For a verification code or signup mail, search recent messages by sender or subject, read the match, and give the user the code or link. `message read` leaves flags unchanged.

Flags follow `himalaya <command> --help`.

## Send

When the user already gave the recipient, subject, and body and asked to send:

```bash
himalaya message compose --to ADDR --subject TEXT --body TEXT --send
```

When any of those is missing, fill the gaps, show the draft, and add `--send` only after the user confirms.
