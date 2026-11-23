# Cosmarchy launcher plugin — design

Date: 2026-11-23. Status: approved. Phase 2 of the Cosmarchy pivot
(phase 1: `2026-11-23-cosmarchy-pivot-design.md`).

## Decision

Phase 1 planned a libcosmic (Rust) control center. It is **not** built.
libcosmic has no bindings outside Rust, and a compiled binary does not fit a
distribution delivered as a git repository advanced by `git pull` (own pacman
repo, release-asset downloader or on-machine `cargo build` were all rejected).

Instead the menu, keybindings and manual become a **plugin for COSMIC's own
launcher** (`cosmic-launcher`, built on `pop-launcher` 1.11). Plugins may be
written in any language, so it lives in the repo, updates with `git pull`, needs
no build, and looks native because it *is* the stock launcher.

Scope: three read/act surfaces — actions, keybindings (read-only), manual
pages. No rebinding, no new pages (snapshots, updates, web apps stay actions).

## Verified facts (2026-11-23)

- `pop-launcher` 1.11.0 is in Arch `extra`; `cosmic-launcher` depends on it.
- Plugin directories: `~/.local/share/pop-launcher/plugins/<name>/`,
  `/etc/pop-launcher/plugins/<name>/`, `/usr/lib/pop-launcher/plugins/<name>/`.
  Each holds `plugin.ron` and an executable named by `bin: (path: "...")`.
- `plugin.ron` example (web plugin):
  ```ron
  (
      name: "Web search",
      description: "Syntax: { ddg | google | ... } <keywords>",
      query: (help: "ddg ", priority: High),
      bin: (path: "web"),
      icon: Name("system-search"),
      history: true,
  )
  ```
  `query` also takes `regex: "<pattern>"` (only matching queries reach the
  plugin) and `isolate: true` (only this plugin answers when it matches).
- IPC is line-based JSON over stdin/stdout; never log to stdout. Logs go to
  stderr. Types (pop-launcher `src/lib.rs`, master = epoch-1.11.0):
  - `Request`: `Activate(u32)`, `ActivateContext{id,context}`, `Complete(u32)`,
    `Context(u32)`, `Exit`, `Close`, `Interrupt`, `Quit(u32)`, `Search(String)`.
  - `PluginResponse`: `Append(PluginSearchResult)`, `Clear`, `Close`,
    `Context{id,options}`, `Deactivate`, `DesktopEntry{...}`, `Fill(String)`,
    `Finished`.
  - `PluginSearchResult`: `id: u32`, `name`, `description`,
    `keywords: Option<Vec<String>>`, `icon: Option<IconSource>`,
    `exec: Option<String>`, `window: Option<(u32,u32)>`.
  - serde externally tagged enums: `{"Search":"c snap"}`, `"Finished"`,
    `{"Append":{...}}`. Confirm whether the plugin receives the query with the
    `c ` prefix (the web plugin receives its `ddg ` prefix) by reading an
    official plugin's source before relying on it.
- `cosmic-launcher input "<text>"` (clap subcommand `Input { input }`, also
  delivered by D-Bus activation to a running instance) opens the launcher
  with the search box prefilled.
- Check that no stock pop-launcher plugin already claims the `c ` prefix.

## User experience

Entry is the stock launcher with prefix `c `:

| Shortcut | Spawns |
|---|---|
| `Super+Alt+Space` | `cosmic-launcher input "c "` — all Cosmarchy actions |
| `Super+Alt+/` | `cosmic-launcher input "c key "` — keybindings |
| `Super+Alt+M` | `cosmic-launcher input "c man "` — manual pages |

Typing the same after `Super` works too.

- **Actions** (`c snap` → "Create snapshot"). Three modes:
  - `run` — executes and closes the launcher (tiling toggle, capture);
  - `notify` — runs and shows its output with `notify-send` (tiling status,
    gaming status);
  - `terminal` — opens `cosmic-term -e <cmd>` for anything needing input or
    confirmation (web app add/remove, snapshot restore, power actions), reusing
    the existing gum flows.
- **Keybindings** (`c key screen` → `Ctrl + Print — Annotate Screenshot`):
  reference only; activating closes the launcher.
- **Manual** (`c man snap` → "14 · Snapshots"): activating opens
  `cosmic-term -e cosmarchy-manual 14`.

`cosmarchy-menu` stays for SSH/TTY but becomes a flat `gum filter` list over
the same action catalog, replacing the nested submenus. `cosmarchy-keybindings`
and `cosmarchy-manual` keep their text modes unchanged.

## Architecture

```
launcher/
  actions.tsv                 the action catalog — single source of truth
  cosmarchy/
    plugin.ron                regex "^c ", isolate: true, help: "c "
    cosmarchy-launcher        Python 3, stdlib only, executable
```

`launcher/` must not live under `bin/` (`install/config/symlinks.sh` publishes
everything there as a command).

**`actions.tsv`** — header line, then one action per line, tab-separated:
`id  title  keywords  mode  command`. `mode` ∈ {`run`, `notify`, `terminal`}.
Readable by bash and Python without a library. Commands use the `cosmarchy*`
names, which resolve through `/usr/local/bin` in the session.

**The plugin is a thin adapter**, no duplicated logic:
- keybindings from `cosmarchy-keybindings --list` (it already parses COSMIC's
  `defaults` and Cosmarchy's `custom` RON — no second RON parser);
- manual pages from `cosmarchy-manual --list`;
- actions from `actions.tsv` (located via `COSMARCHY_PATH`, default
  `~/.local/share/cosmarchy`).

Sources load once at plugin start (pop-launcher keeps the process alive).
Matching: case-insensitive; every word of the query (after the `c ` / `key ` /
`man ` sub-prefix) must appear in `title + keywords`. At most 8 results.
`c ` alone lists actions; `c key` and `c man` restrict to that kind.

**Activation**: detach the command (`setsid`, stdio to `/dev/null`), reply
`Close`. Keybinding results reply `Close` only.

**Errors**: a source that fails to load yields one result
`Cosmarchy: <source> unavailable — <reason>` instead of an empty list, and the
reason goes to stderr. Every `Search` ends with `Finished`, even on error.

**Install**: new stage `install/config/launcher.sh` symlinks
`~/.local/share/pop-launcher/plugins/cosmarchy` →
`$COSMARCHY_PATH/launcher/cosmarchy`. Works inside the chroot. Add
`pop-launcher` explicitly to `cosmarchy-base.packages` (verify the name).

**Shortcuts**: `default/cosmic/.../custom` changes the three `cosmic-term -e`
entries to the `cosmic-launcher input` spawns above.

**Migration** `migrations/<YYYY-MM-DD-HHMM>-launcher-plugin.sh` (v0.1.0
machines exist): idempotently create the symlink, and replace each of the three
old `Spawn("cosmic-term -e cosmarchy-…")` values in the user's `custom` only
when the line is exactly the shipped v0.1.0 value — a key the user rebound is
left alone. Atomic write via `cosmarchy_cosmic_write`-style temp + `mv`.

## Verification

Fast tests (`iso/tests/unit.sh`):
- `iso/tests/test-launcher-plugin.sh`: run the plugin with a fake
  `COSMARCHY_PATH` and stub `cosmarchy-keybindings` / `cosmarchy-manual` on
  `PATH`; feed JSON lines and assert: `c snap` → Create snapshot; `c key
  screen` → `Ctrl + Print`; `c man snap` → page 14; `Activate` of a `run`
  action executes its command (stub writes a marker file); a broken source
  yields the error result; every line is valid JSON; every Search ends with
  `Finished`.
- `actions.tsv`: 5 fields per line, valid `mode`, every command's executable
  exists in `bin/`.
- Migration: rewrites the three v0.1.0 lines, is a no-op on second run, leaves
  a user-rebound line untouched.
- shellcheck on new bash; `python3 -m py_compile` on the plugin.

`iso/tests/verify-install.sh`: plugin symlink (`-L`), `plugin.ron` and
executable present; `custom` contains the `cosmic-launcher input` spawns;
`pop-launcher` installed.

`iso/tests/verify-session.sh`: run the real `pop-launcher`, write
`{"Search":"c snap"}` to its stdin, and assert a response contains "Create
snapshot" — proves COSMIC's launcher discovers the plugin.

## Documentation

Same commit series: `manual/` (menu and keybindings pages), README, CLAUDE.md
(layout, the plugin, "Things deliberately not done": the libcosmic control
center is replaced by the launcher plugin), AGENTS.md, TESTING.md,
`default/cosmarchy-skill/SKILL.md`, `site/`. Phase 1's spec mentions of a
future libcosmic control center are history; current docs must not promise it.

## Out of scope

Rebinding shortcuts; a windowed UI of any kind; snapshot/update/web-app pages;
a VERSION bump or release (cut separately, only from a green smoke test).
