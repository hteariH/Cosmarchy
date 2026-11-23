# CLAUDE.md

Guidance for Claude Code working in this repository.

## What this is

Cosmarchy is an Arch Linux distribution: Omarchy's tooling and rolling base
with the stock **COSMIC 1.11** desktop (Wayland + `greetd`/`cosmic-greeter`)
instead of Hyprland. It ships as an installable ISO and as a config repository
that lives at `~/.local/share/cosmarchy` on installed machines.

Two things follow from that and shape everything else:

1. **Editing a file here only affects new installs.** Machines already running
   need a migration. See *Migrations*.
2. **COSMIC config is plain RON files**, deployed directly inside `arch-chroot`
   without needing a live D-Bus session bus. Only live-session hardware work
   (PipeWire / seat) belongs in `cosmarchy-first-run`. See *The chroot boundary*.

## Layout

```
bin/                     the cosmarchy CLI; one file per subcommand
install/
  preflight/             guards, pacman setup (enables multilib)
  packaging/             package installation (official repos, Flatpak, Brave Origin)
  config/                system and user configuration
    hardware/            per-vendor profiles, sourced by all.sh
  desktop/               COSMIC RON deployment (cosmic.sh, set-keyboard-layout.sh)
                         and live-session hardware tweaks (set-hardware-session.sh)
  helpers/               presentation, logging, errors, chroot, cosmic RON helpers
  login/                 cosmic-greeter/greetd (greeter.sh), Plymouth, Limine (boot.sh)
  post-install/          cleanup, migration baseline
  cosmarchy-base.packages   pacman list, official repos only
migrations/              timestamped, once-per-machine repair scripts (starts empty)
manual/                  15 numbered pages read by `cosmarchy manual`
iso/
  builder/build-iso.sh   archiso profile assembly
  installer/             the gum installer (cosmarchy-install + lib/)
  configs/airootfs/root/.automated_script.sh   starts iso/installer/cosmarchy-install on tty1
  tests/                 unit tests (unit.sh) and smoke-test verification scripts
default/                 files deployed onto the installed system
  cosmic/                behaviour-only COSMIC RON config tree (autotile, shortcuts)
  boot/                  cosmarchy-boot, fixed COSMIC Dark boot-theme.conf, snapper plugin,
                         pacman hooks, initcpio install and post hooks (deployed root-owned)
  cosmarchy-skill/       AI agent skill (SKILL.md)
```

`install.sh` sources the stages in order and wraps each in `run_stage`, which
prints `STAGE START` / `STAGE OK` markers into the install log.

## The chroot boundary

The ISO installer runs `install.sh` under `arch-chroot -u $USERNAME`. In that
context:

- Plain COSMIC RON files under `~/.config/cosmic/<component-id>/v1/<key>` work
  directly — `install/desktop/cosmic.sh` deploys `default/cosmic/` and
  `install/desktop/set-keyboard-layout.sh` writes `xkb_config` inside the chroot
  with no session bus needed.
- `systemctl enable` works (it is offline symlink manipulation).
- Package installation, file deployment and udev rules work.
- Live-session hardware tweaks talking to PipeWire (`pactl`) or the seat cannot
  run inside chroot.

So the rule is:

| Work | Where it goes |
|---|---|
| packages, files, COSMIC RON config, udev, systemd enablement | `install/` stages |
| live-session PipeWire / seat hardware tweaks (e.g. Framework 13 mic profile) | `cosmarchy-first-run` |

### Any autostart entry must not declare a phase

`systemd-xdg-autostart-generator` skips any XDG autostart `.desktop` entry
containing `X-GNOME-Autostart-Phase` because phases cannot be expressed as
units. Never add `X-GNOME-Autostart-Phase` to any autostart entry (such as
`cosmarchy-first-run.desktop`, `cosmarchy-snapshot-notify.desktop`, or
`cosmarchy-firstboot.desktop`).

## COSMIC configuration

`default/cosmic/` mirrors `~/.config/cosmic/` one file per key and holds
**behaviour only** — Cosmarchy keeps authentic stock COSMIC appearance and lets
`cosmic-initial-setup` handle first-login appearance, panel layout, timezone,
Wi-Fi and accessibility:

```
default/cosmic/com.system76.CosmicComp/v1/autotile
default/cosmic/com.system76.CosmicComp/v1/autotile_behavior
default/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom
default/cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions
```

`install/helpers/cosmic.sh` provides `cosmarchy_cosmic_write` and
`cosmarchy_cosmic_deploy` (atomic temp-file + `mv`, no error suppression).
`install/desktop/set-keyboard-layout.sh` reads `/etc/cosmarchy/keyboard.conf`
and writes `com.system76.CosmicComp/v1/xkb_config` (keeping `us` first when
`LATIN=no`).

**Shortcut rule:** COSMIC defaults win. Every binding in `custom` uses a key
absent from `/usr/share/cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults`.
Text tools spawn as `cosmic-term -e <cmd>`.

**First login:** `cosmic-initial-setup` autostarts in the session and exits
immediately when `~/.config/cosmic-initial-setup-done` exists. Unattended (CI)
installs create that marker owned by the user; interactive installs do not.

## Migrations

`migrations/<YYYY-MM-DD-HHMM>-<slug>.sh`, applied exactly once per machine,
recorded in `~/.local/state/cosmarchy/migrations.log`. `cosmarchy update` runs
pending ones after the git pull; `install/post-install/migrations-baseline.sh`
marks them all applied on a fresh install rather than replaying them.

They must be **idempotent** — they may run on a machine in any prior state.

If a change alters behaviour on an existing machine, it needs one. Adding a
package to `cosmarchy-base.packages` alone reaches new installs only.

## Conventions

- `#!/bin/bash`, `[[ ]]` for strings, `(( ))` for arithmetic, `$HOME` never a
  hardcoded path.
- Helpers from `install/helpers/presentation.sh`: `cosmarchy_header`,
  `cosmarchy_step`, `cosmarchy_warn`, `cosmarchy_error`, `cosmarchy_substep`.
  `cosmarchy_error` only prints — add an explicit `exit` if you mean to stop.
- New `bin/cosmarchy-*` commands need a case in `bin/cosmarchy` **and** they are
  symlinked into `/usr/local/bin` by `install/config/symlinks.sh`. Without that
  symlink the COSMIC session cannot find them; it does not read your shell
  profile.
- Files created on a non-Unix host land in git as mode 100644. Run
  `git update-index --chmod=+x` on new scripts, or the installer's `chmod +x`
  will dirty the tree and block the next `git pull`.

### Do not suppress errors by default

Five separate defects shipped because a failure was hidden behind `2>/dev/null`
or `|| true`: schemas never compiled, Brave binaries left non-executable, the
git checkout never created, the install log never written, `cosmarchy update`
reporting success after a failed pull.

Suppress output only where failure genuinely does not matter, and say so in a
comment. Prefer reporting and continuing over silence.

## Verifying package names

`pacman -S` is all-or-nothing: one unknown name aborts the transaction and,
under `set -e`, the installer. Note COSMIC package traps: the terminal is
`cosmic-terminal` (binary `cosmic-term`) and the editor is `cosmic-text-editor`.

Check names against the real databases before adding them:

```bash
curl -sSL "https://archlinux.org/packages/search/json/?name=<pkg>"
curl -sSL "https://aur.archlinux.org/rpc/v5/info?arg[]=<pkg>"
```

`cosmarchy-base.packages` must contain only official-repo packages; AUR belongs
in an opt-in command with an AUR helper and a fallback. COSMIC packages are
listed individually by name (not the `cosmic` group) so
`install/packaging/base.sh` can partition them against the sync DBs.

## Verification

`.github/workflows/install-smoke-test.yml` builds the ISO, **installs from it in
QEMU** and checks the result in two layers:

- `iso/tests/verify-install.sh` — offline, against the mounted image
- `iso/tests/verify-session.sh` — inside a real autologin COSMIC session
  (greetd `[initial_session]` + `~/.config/cosmic-initial-setup-done`)

Every check corresponds to a defect that once shipped or a COSMIC pivot
contract. Add one when you fix something the test would not have caught.

A `unit` job runs first (`iso/tests/unit.sh`: all `iso/tests/test-*.sh` plus
shellcheck) and the install job needs it. The install job runs twice, a `plain`
and an `encrypted` variant; the encrypted one is checked offline only. The plain
variant then boots a COSMIC session, takes a snapshot, boots that snapshot and
restores it. Session reports are under `~/.local/state/cosmarchy/verify/`
(`session.txt`, `snapshot.txt`) because a snapshot boot's `/var/tmp` is
volatile.

**Cut a release only from a commit where this job is green.** The release
workflow only proves the ISO builds; five releases shipped installation
defects through green builds.

### Mounting the installed image

The filesystem is split. Mounting less than this silently empties directories
and turns every check against them into a false failure:

```
/dev/nbd0p3  subvol=@         /
/dev/nbd0p3  subvol=@home     /home
/dev/nbd0p3  subvol=@var_log  /var/log
/dev/nbd0p3  subvol=@snapshots /.snapshots
/dev/nbd0p2                   /boot     (EFI partition, holds limine.conf)
```

On the encrypted variant the Btrfs is `/dev/mapper/ci-root`, opened from
`/dev/nbd0p3` with the answers' password.

Also: absolute symlinks inside a mounted image resolve against the **host**
filesystem, so `-e` is false however correct the link is. Test with `-L`.

### Driving the installer unattended

Answers are read from a file on a device labelled `COSMARCHY`, so the ISO under
test stays byte-identical to the one that ships. FAT labels are capped at 11
characters.

```bash
printf '%s\n' 'COSMARCHY_DISK=/dev/vda' 'COSMARCHY_USERNAME=citest' \
  'COSMARCHY_PASSWORD=test' 'COSMARCHY_ENCRYPT=n' > cosmarchy-unattended.conf
truncate -s 8M answers.img && mkfs.vfat -n COSMARCHY answers.img
mcopy -i answers.img cosmarchy-unattended.conf ::/
```

## Diagnosing a failure

```bash
/var/log/cosmarchy-installer.log              the installer's own log; the [n/7] lines show the stage
/var/log/cosmarchy-install.log                installation; STAGE markers show where it stopped
/var/log/pacman.log                           cosmarchy-boot output from the pacman hooks
journalctl --user -b -u cosmic-comp           compositor logs
journalctl --user -b | grep -i cosmic-settings-daemon   shortcut / config daemon errors
journalctl --user -t cosmarchy-first-run      session hardware setup (Framework 13)
journalctl --user -t cosmarchy-verify         the CI session check
cosmarchy version --verbose                   version, autotile state, migrations applied
```

## The bootloader and snapshots

`cosmarchy-boot` is the only thing that writes `/boot/limine.conf`. It
regenerates the whole file from `/etc/kernel/cmdline`, the kernels on the ESP,
per-snapshot records in `/boot/cosmarchy/entries/` and the fixed COSMIC Dark
palette in `/etc/cosmarchy/boot-theme.conf` (deployed from
`default/boot/boot-theme.conf`). Change the command line in
`/etc/kernel/cmdline`, never in `limine.conf`, then run `cosmarchy boot update`.

What regenerates it: the `Target = *` pacman hook, the snapper plugin, and the
mkinitcpio post hook `/etc/initcpio/post/cosmarchy-boot`, which catches a
hand-run `mkinitcpio -P`. Kernel entries carry a `#b2sum`, so a stale menu would
otherwise panic; `hash_mismatch_panic: no` turns that into a warning.

`00-cosmarchy-guard.hook` runs `cosmarchy-boot guard` before every pacman
transaction and aborts it on a snapshot boot (`cosmarchy.snapshot=` on the
command line) or with a restore pending (root FSROOT `/@restore-backup-*`):
the ESP survives the reboot and the root does not, so a kernel upgrade would
leave a kernel with no modules. `cosmarchy update` asks the same guard first.

It runs as root from `/usr/local/lib/cosmarchy/boot/`, copied there by
`default/boot/deploy.sh` (installer, `install.sh`, `cosmarchy update`). Root
never executes scripts from a user's home.

Snapshot kernels are content-addressed in `/boot/cosmarchy/store/`; a
snapshot boots read-only under `systemd.volatile=overlay`, which needs the
`cosmarchy-overlay` initcpio hook. fstab must not contain `subvolid=`.

`cosmarchy-boot`'s fast tests run its real code against a fake tree through
`COSMARCHY_BOOT_ROOT`: `iso/tests/unit.sh`, in an archlinux container.

## Documentation is a claim about the code

If you change behaviour, change `README.md`, `CLAUDE.md`, `AGENTS.md`,
`TESTING.md`, `default/cosmarchy-skill/SKILL.md`, `site/`, and the relevant
`manual/` page in the same commit — and if you find a claim nothing backs,
either implement it or remove it rather than leaving it.

## Things deliberately not done

- No custom theme engine or downloaded wallpapers: Cosmarchy uses authentic
  stock COSMIC appearance and `cosmic-wallpapers`.
- No GNOME desktop support, dconf overrides, or GTK/GJS control center (the
  menu, keybindings, and manual are text-only until a future libcosmic control
  center).
- `grep`, `find` and `cat` are not aliased to ripgrep, fd and bat.
