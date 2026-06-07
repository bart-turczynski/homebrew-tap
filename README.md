# bart-turczynski/homebrew-tap

Homebrew tap for [`unbreak`](https://github.com/bart-turczynski/unbreak) — repairs
terminal-wrapped clipboard commands from grid-renderer agent CLIs (Claude Code,
Gemini CLI, Codex CLI) so they paste as clean, runnable shell commands. macOS only.

## Install

```sh
brew install bart-turczynski/tap/unbreak
```

`brew install` only puts the `unbreak` CLI on your `PATH`. The clipboard watcher is
**off until you opt in** — enable it at login with `brew services start unbreak`, or
run the guided `unbreak setup`.

See the [main repo](https://github.com/bart-turczynski/unbreak) for full docs.
