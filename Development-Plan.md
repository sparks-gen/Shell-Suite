# Shell Suite — Development Plan

**Status:** Planning / pre-implementation

## 1. Goal

Consolidate scattered shell customizations into one repo that a bare-minimum `[$SHELL]rc` file sources. Originated from `transfer.sh` (standardizing data transfer) and the realization that colleagues might want its notification abilities too, plus a general goal of stopping personal shell customizations from leaking across machines.

## 2. Components

| Component | Tier | Source | Notes |
|---|---|---|---|
| `transfer.sh` | Vendored | `Data-Transfer` repo | ~~Currently hard-depends on `notify`~~ — D2 fixed: now checks `notify` exists before using it |
| `notify.sh` | Vendored | `Shell-Custom` repo | |
| SSH shortcuts | Native | this repo | Parses `Host` entries in `~/.ssh/config` into aliases/functions |
| Secrets sync | Native | this repo | Syncs settings too sensitive for GitHub (e.g. Claude's settings dir); deliberately last, see Q2 |
| One-off custom commands | Native | this repo, `commands/` | Small, single-file aliases/functions with no independent tests/dependencies/history — see D7 |

Vendored components install independently, selected via `sources.list` — see D1, D6. Native components ship with Shell-Suite itself; no selection step, no clone. `commands/` is specifically for the one-off tier — SSH shortcuts and secrets sync are native too, but substantial enough to warrant their own dedicated files rather than living alongside single-purpose aliases.

## 3. Decisions

Settled design calls, in the order they were made. Kept as a log rather than deleted once superseded, so the reasoning isn't lost.

| # | Decision | Rationale |
|---|---|---|
| D1 | Multi-repo: one root repo installs selected sub-repos, not a single monolith | Four concerns (transfer, notify, secrets, ssh) are functionally unrelated; bundling them removes the ability to install only what's needed |
| D2 | `transfer.sh`'s dependency on `notify` becomes an optional runtime check, not a hard require | Contradicts D1 otherwise — installing `transfer.sh` alone must still work |
| D3 | POSIX `sh` requirement narrowed to the rc-sourced glue only (PATH/aliases/dispatcher) — `transfer.sh`, `notify.sh`, `install.sh`, and `shell-suite install` all stay bash | Revised after [POSIX-COMPLIANCE.md](POSIX-COMPLIANCE.md) audit of `Data-Transfer`. A `#!/usr/bin/env bash` shebang forces bash regardless of the caller's login shell, and bash ships everywhere this needs to run — so only code actually *sourced into* `.zshrc`/`.bashrc` is exposed to the bash/zsh syntax divide. `install.sh` qualifies for bash too: it runs as its own process and only needs to *write* the sourcing line into the rc file, not mutate the caller's live shell directly. Avoids a redesign of `rsync-wrapper.sh`'s array-based arg building, which has no POSIX equivalent at all |
| D4 | Installs to `~/.shell-suite`, nothing loose in `~` | Keeps home directory uncluttered |
| D5 | Update check runs once a day, not on every shell load | A per-shell-load check would add latency to every new terminal/tab |
| D6 | Sub-repos installed via plain `git clone` into subdirectories of `~/.shell-suite`, selected from a flat pipe-delimited manifest (`sources.list`: `name\|url\|description`) — not git submodules or subtree | Submodules/subtree pin vendored code into the parent repo's own history, built for "my build depends on this exact commit" — wrong shape for "let the user pick a subset at install time." A manifest + plain clone is what dotfile/plugin frameworks (antigen, zinit, chezmoi) use for this same problem, and each cloned source stays an independent repo, simplifying D5's daily-update check |
| D7 | Two-tier component model: **vendored** (own repo, gated behind `sources.list` + D6's clone step) vs. **native** (small, single-file commands committed directly into Shell-Suite, no manifest entry, no clone), living in a `commands/` directory. Rule of thumb: independent tests/dependencies/release history → vendored; a single file/function with no concerns of its own → native, in `commands/` | Spinning up a whole separate repo (plus a `sources.list` entry and a clone step) is overkill for something as small as one alias or function — that overhead only pays for itself once a component is substantial enough to warrant its own repo-level concerns. Formalizes what the Components table already implied (SSH shortcuts and secrets sync never had an external source) rather than introducing a new mechanism |

## 4. Open Questions

Unresolved, blocking implementation of the relevant component only.

| # | Question | Status |
|---|---|---|
| Q2 | Secrets sync mechanism — symlinks to an untracked dir? `git-crypt`/`age`? separate private repo? | Deliberately deferred until other components are working (see D5's "Mac as hub" framing) |

## 5. Roadmap

Phased so later work doesn't get blocked on the riskiest piece (secrets sync).

1. ✅ **Fix `transfer.sh`/`notify` coupling (D2)** — done, in the `Data-Transfer` repo itself. `transfer.sh` and `notify.sh` are *not* moved or copied into Shell-Suite — they stay independent repos at their own locations/remotes, per D1. Shell-Suite never holds their code directly.
2. **Install mechanism** — build the `shell-suite install` selection flow (D1, D4, D6) that reads `sources.list` and runs `git clone <url> ~/.shell-suite/<name>` for whatever's selected. This is the only point either script's code actually arrives on a machine — as a fresh clone, not a copy baked into this repo. Only the tiny snippet that actually gets *sourced* into the rc file (PATH export, dispatcher alias) needs D3's POSIX restriction — `shell-suite install` itself runs as its own process via shebang, so it can be plain bash, same as `transfer.sh`/`notify.sh`.
3. **SSH shortcuts** — generate aliases/functions from `~/.ssh/config`.
4. **Secrets sync** — design and implement last (Q2).

## 6. Risks

- **Secrets sync** is the one component whose failure mode is an actual leak, not just a bug — worth extra scrutiny whenever Q2 gets designed.
- **Bash-availability assumption (D3):** narrowing POSIX to the rc glue relies on bash being present on every target machine. True for macOS/Linux/WSL by default, but worth a sanity check if this ever needs to run somewhere more exotic.
