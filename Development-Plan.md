# Shell Suite — Development Plan

**Status:** Planning / pre-implementation

## 1. Goal

Consolidate scattered shell customizations into one repo that a bare-minimum `[$SHELL]rc` file sources. Originated from `transfer.sh` (standardizing data transfer) and the realization that colleagues might want its notification abilities too, plus a general goal of stopping personal shell customizations from leaking across machines.

## 2. Components

| Component | Source | Notes |
|---|---|---|
| `transfer.sh` | `Data-Transfer` repo | Currently hard-depends on `notify` — needs decoupling (see D2) |
| `notify.sh` | `Shell-Custom` repo | |
| SSH shortcuts | generated from `~/.ssh/config` | Parses `Host` entries into aliases/functions |
| Secrets sync | new | Syncs settings too sensitive for GitHub (e.g. Claude's settings dir); deliberately last, see D6 |

Each component installs independently — see D1.

## 3. Decisions

Settled design calls, in the order they were made. Kept as a log rather than deleted once superseded, so the reasoning isn't lost.

| # | Decision | Rationale |
|---|---|---|
| D1 | Multi-repo: one root repo installs selected sub-repos, not a single monolith | Four concerns (transfer, notify, secrets, ssh) are functionally unrelated; bundling them removes the ability to install only what's needed |
| D2 | `transfer.sh`'s dependency on `notify` becomes an optional runtime check, not a hard require | Contradicts D1 otherwise — installing `transfer.sh` alone must still work |
| D3 | POSIX `sh` requirement narrowed to the rc-sourced glue only (PATH/aliases/dispatcher) — `transfer.sh`, `notify.sh`, and their supporting scripts stay bash | Revised after [POSIX-COMPLIANCE.md](POSIX-COMPLIANCE.md) audit of `Data-Transfer`. A `#!/usr/bin/env bash` shebang forces bash regardless of the caller's login shell, and bash ships everywhere this needs to run — so only code actually *sourced into* `.zshrc`/`.bashrc` is exposed to the bash/zsh syntax divide. Avoids a redesign of `rsync-wrapper.sh`'s array-based arg building, which has no POSIX equivalent at all |
| D4 | Installs to `~/.shell-suite`, nothing loose in `~` | Keeps home directory uncluttered |
| D5 | Update check runs once a day, not on every shell load | A per-shell-load check would add latency to every new terminal/tab |

## 4. Open Questions

Unresolved, blocking implementation of the relevant component only.

| # | Question | Status |
|---|---|---|
| Q1 | Install-sources manifest format — how does `shell-suite install` know what's available to select? | Next task to define — unblocks Phase 2 below |
| Q2 | Secrets sync mechanism — symlinks to an untracked dir? `git-crypt`/`age`? separate private repo? | Deliberately deferred until other components are working (see D5's "Mac as hub" framing) |

## 5. Roadmap

Phased so later work doesn't get blocked on the riskiest piece (secrets sync).

1. **Wire up existing scripts** — bring `transfer.sh` / `notify.sh` in as-is (bash, per D3), fix the `notify` dependency (D2). No POSIX port needed for these — see D3.
2. **Install mechanism** — define the sources manifest (Q1), build `shell-suite install` and the sub-install/selection flow (D1, D4). This is the piece D3 actually requires POSIX `sh` for, since it's what gets sourced into the rc file.
3. **SSH shortcuts** — generate aliases/functions from `~/.ssh/config`.
4. **Secrets sync** — design and implement last (Q2).

## 6. Risks

- **Secrets sync** is the one component whose failure mode is an actual leak, not just a bug — worth extra scrutiny whenever Q2 gets designed.
- **Bash-availability assumption (D3):** narrowing POSIX to the rc glue relies on bash being present on every target machine. True for macOS/Linux/WSL by default, but worth a sanity check if this ever needs to run somewhere more exotic.
