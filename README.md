# claude-status-notify

A small Linux desktop utility I put together to watch Claude's public status page and send a notification when a Claude service changes state.

It is meant to be lightweight and boring in a good way: poll the public status endpoint, remember the last known state of each service, and only notify when something actually changes.

Right now it checks the public Claude Status summary feed and tracks components such as:

- `claude.ai`
- `platform.claude.com`
- `Claude API (api.anthropic.com)`
- `Claude Code`
- `Claude for Government`

## What it does

- Polls Claude's public status API on a timer
- Tracks each service separately
- Sends a desktop notification only when a service status changes
- Avoids repeat notifications for the same ongoing issue
- Supports a manual `--notify-now` mode to show the current state immediately

## Why I made it

Mostly for myself.

I wanted a simple way to notice when Claude had a real service issue without constantly checking the status page, and I only wanted notifications on state changes rather than repeated reminders.

## Requirements

This was built for Ubuntu/Linux with:

- `bash`
- `curl`
- `jq`
- `notify-send` from `libnotify-bin`
- `systemd --user`

Install dependencies on Ubuntu:

```bash
sudo apt update
sudo apt install curl jq libnotify-bin
```

## Files

Repo layout:

```text
claude-status-notify/
├── claude-status-notify.sh
├── claude-status-notify.service
├── claude-status-notify.timer
├── README.md
└── LICENSE
```

## How it works

The script calls Claude's public status summary endpoint:

```text
https://status.claude.com/api/v2/summary.json
```

It reads the component list, stores the last seen status for each component in a local state directory, and compares the latest values against the saved baseline.

On normal runs:
- first run creates the baseline and stays quiet
- later runs notify only when a component changes state

With `--notify-now`:
- it immediately shows notifications for the current status of each component
- it also refreshes the saved baseline

## Install

Clone the repo:

```bash
git clone https://github.com/amalakhovsky/claude-status-notify.git
cd claude-status-notify
```

Make the script executable and copy it to `~/bin/`:

```bash
chmod +x claude-status-notify.sh
mkdir -p ~/bin
cp claude-status-notify.sh ~/bin/
```

Create the user systemd directory if needed:

```bash
mkdir -p ~/.config/systemd/user
```

Copy the unit files into place:

```bash
cp claude-status-notify.service ~/.config/systemd/user/
cp claude-status-notify.timer ~/.config/systemd/user/
```

Reload and enable the timer:

```bash
systemctl --user daemon-reload
systemctl --user enable --now claude-status-notify.timer
```

Check that the timer is active:

```bash
systemctl --user list-timers | grep claude-status-notify
```

## Manual usage

Normal run:

```bash
./claude-status-notify.sh
```

Force a notification of the current status:

```bash
./claude-status-notify.sh --notify-now
```

Short form:

```bash
./claude-status-notify.sh -n
```

## State storage

The script keeps local state under:

```text
$XDG_STATE_HOME/claude-status-monitor/components
```

If `XDG_STATE_HOME` is not set, it falls back to:

```text
~/.local/state/claude-status-monitor/components
```

That state is what prevents repeated notifications for the same unchanged outage.

## Notes

- This is a personal utility script, not an official Anthropic tool.
- It depends on the public Claude status page/API being available.
- It is intentionally simple and desktop-focused.
- Notifications are informational only; they are not marked urgent.

## License

MIT
