# AGENTS.md

Agent guidelines for working in the Cosmarchy repository. See `CLAUDE.md` for
the full architecture, bootloader/snapshot layout, and verification details.

## Desktop & configuration

- Cosmarchy runs the stock **COSMIC 1.11** desktop on Wayland with
  `cosmic-greeter` on `greetd`. There is no GNOME, no dconf, no theme engine,
  and no windowed `gui/` or libcosmic control center. Instead, Cosmarchy ships
  a `pop-launcher` plugin (Python 3, stdlib only) under `launcher/cosmarchy/`
  and a single action catalog at `launcher/actions.tsv` (`c `, `c key `,
  `c man `), alongside text CLI fallbacks (`cosmarchy-menu`,
  `cosmarchy-keybindings`, `cosmarchy-manual`).
- `launcher/` must never live under `bin/` (`install/config/symlinks.sh`
  publishes everything matching `bin/cosmarchy*` into `/usr/local/bin`).
- COSMIC configuration lives as plain RON files under `default/cosmic/`,
  deployed atomically into `~/.config/cosmic/` inside `arch-chroot` by
  `install/helpers/cosmic.sh` (`cosmarchy_cosmic_deploy` /
  `cosmarchy_cosmic_write`).
- Installer keyboard layout selection writes
  `com.system76.CosmicComp/v1/xkb_config` via
  `install/desktop/set-keyboard-layout.sh`.
- COSMIC default shortcuts win: any custom binding in
  `default/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom` must use a
  key absent from `/usr/share/cosmic/com.system76.CosmicSettings.Shortcuts/v1/defaults`.

## Commands & scripts

- `install/config/symlinks.sh` publishes everything matching `bin/cosmarchy*`
  into `/usr/local/bin` so COSMIC shortcuts can execute them without reading a
  shell profile. Never place non-command source trees under `bin/`.
- Set the executable bit in git (`git update-index --chmod=+x`) on any new
  script created on a non-Unix host.
- Never add `X-GNOME-Autostart-Phase` to any XDG autostart `.desktop` file.
- Verify any official Arch package name against
  `https://archlinux.org/packages/search/json/?name=<pkg>` before adding it to
  `install/cosmarchy-base.packages`.

## Fast tests

Run the fast test suite and shellcheck in an Arch container before cutting a
change:

```bash
docker run --rm -v "$PWD:/w" -w /w archlinux:latest bash iso/tests/unit.sh --deps
```
