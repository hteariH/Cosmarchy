# Troubleshooting

## Keyboard shortcuts do not work

Cosmarchy's COSMIC shortcuts live as plain RON files under:

    ~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom
    ~/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/system_actions

Check whether `cosmic-settings-daemon` logged a parse error:

```bash
journalctl --user -b | grep -iE "shortcuts custom config error|system_actions|Skipping over invalid"
```

Re-deploy Cosmarchy's defaults at any time:

```bash
cosmarchy keybindings reset
```

## Tiling does nothing

```bash
cosmarchy tiling status
cosmarchy tiling enable
```

Check `~/.config/cosmic/com.system76.CosmicComp/v1/autotile` (`true`) and
`autotile_behavior` (`PerWorkspace`). Press `Super + Y` to toggle tiling on the
active workspace.

## Keyboard layout is wrong

The installer writes `/etc/cosmarchy/keyboard.conf` and turns it into
`~/.config/cosmic/com.system76.CosmicComp/v1/xkb_config`. You can inspect or
re-apply it with:

```bash
cat ~/.config/cosmic/com.system76.CosmicComp/v1/xkb_config
bash ~/.local/share/cosmarchy/install/desktop/set-keyboard-layout.sh
```

Or adjust input sources in **COSMIC Settings → Input Devices → Keyboard**.

## Login greeter / keyring issues

Cosmarchy uses `cosmic-greeter` on `greetd` (`/etc/greetd/cosmic-greeter.toml`):

```bash
systemctl status cosmic-greeter.service
journalctl -b -u cosmic-greeter.service
```

## cosmarchy update says nothing changed

Check that it is actually tracking a repository:

```bash
git -C ~/.local/share/cosmarchy status -sb
```

## A kernel command-line change does nothing

The boot menu is generated from `/etc/kernel/cmdline`, and editing that file
alone does not regenerate it:

```bash
cosmarchy boot update
```

The same applies if Limine warns of a hash mismatch at boot: the menu names a
kernel or initramfs that has changed since it was written. Press a key to boot
anyway, then run `cosmarchy boot update`.

## pacman says "this system is running snapshot N"

You booted a snapshot from the menu, and package changes there would be lost at
the next reboot while the kernel they install would not. Reboot into the normal
entry, or make the snapshot the system with `cosmarchy snapshot restore N` and
reboot. "A restore is pending" means a restore already ran: reboot first.

## A command is not found from a keybinding

Every `cosmarchy-*` command must be symlinked into `/usr/local/bin` to be
reachable from the COSMIC session, which does not read your shell profile.

```bash
ls /usr/local/bin/cosmarchy*
cosmarchy update
```

## Getting more detail

    /var/log/cosmarchy-installer.log              the installer, with the failing stage
    /var/log/cosmarchy-install.log                installation
    journalctl --user -b -u cosmic-comp           compositor logs
    journalctl --user -t cosmarchy-first-run      session hardware setup (Framework 13)
    cosmarchy version --verbose                   version, autotile state, migrations applied
