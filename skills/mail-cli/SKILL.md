---
name: mail-cli
description: >-
  Send and read mail with the local Himalaya CLI. Use when the user wants to
  send or read email, check an inbox, grab a signup or verification message,
  or set up a Gmail account for Himalaya.
---

# mail-cli

Send and read mail with the local `himalaya` CLI. Account addresses and app passwords stay on the machine, not in this skill.

## Setup

Run `scripts/setup.sh` with the Gmail address. It installs `scripts/himalaya-gmail-secret` to `~/.local/bin/himalaya-gmail-secret`, then writes `~/.config/himalaya/config.toml` from `scripts/gmail.config.toml`. Only the address is filled in. IMAP, SMTP, the password command, and the Gmail mailbox aliases stay as they are in the template.

```bash
scripts/setup.sh name@gmail.com
```

When an account is already configured, setup installs the helper and stops. It does not rewrite or remove the account.

Then tell the user to write the Google app password to `~/.config/himalaya/gmail-app-password` (mode 600, the app password only). Create it at https://myaccount.google.com/apppasswords.

Before the first read or send in a session:

```bash
himalaya account list --json
himalaya account check
```

`account list` is the bound accounts: `name`, `default`, and `backends`. Use the default account. When the user names one, pass `-a <name>`.

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
