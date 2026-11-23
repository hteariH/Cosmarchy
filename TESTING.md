# Cosmarchy Verification & Testing Guide

This guide details the procedure for testing Cosmarchy scripts, the fast unit suite, the live ISO build, and the installed COSMIC environment.

---

## 0. Automated Install Smoke Test (CI)

`.github/workflows/install-smoke-test.yml` builds the ISO, **installs from it in QEMU**, and verifies the result. It runs on pushes to `main`, on pull requests touching `iso/`, `install/`, `bin/` or `default/`, and on demand via `workflow_dispatch`.

The installer is driven by an answers file on a separate disk labeled `COSMARCHY`, so **the ISO under test is byte for byte the ISO that ships**. To reproduce locally:

```bash
printf '%s\n' 'COSMARCHY_DISK=/dev/vda' 'COSMARCHY_FULLNAME="Test User"' \
  'COSMARCHY_USERNAME=citest' 'COSMARCHY_PASSWORD=test-password' \
  'COSMARCHY_ENCRYPT=n' 'COSMARCHY_HOSTNAME=citest-host' \
  'COSMARCHY_TIMEZONE=Europe/Berlin' 'COSMARCHY_KEYMAP=de' \
  > cosmarchy-unattended.conf
# With COSMARCHY_ENCRYPT=y, add COSMARCHY_DISK_PASSWORD=<passphrase> (optional;
# without it the user's password is used).

truncate -s 8M answers.img
mkfs.vfat -n COSMARCHY answers.img
mcopy -i answers.img cosmarchy-unattended.conf ::/
```

Attach `answers.img` as a second drive and the installer runs without prompts. Unattended installs also create `~/.config/cosmic-initial-setup-done` (owned by the user) so the live session boots straight to the desktop without blocking on the first-run wizard.

The workflow has these layers:

- **`unit` job** (`iso/tests/unit.sh`, in `archlinux:latest`): boot menu generation, fixed COSMIC Dark palette validation, COSMIC RON config deployment & `xkb_config` mapping, `deploy.sh`, installer validation and stage rules, and `shellcheck`. Run locally with:
  ```bash
  docker run --rm -v "$PWD:/w" -w /w archlinux:latest bash iso/tests/unit.sh --deps
  ```
- **Encrypted variant**: the install job runs `plain` and `encrypted`. The encrypted image is verified offline (including LUKS kernel command line and greetd `[initial_session]` autologin).
- **Offline verification** (`iso/tests/verify-install.sh`): `cosmic-greeter.service` enabled, no GDM unit, PAM keyring integration on the service named in `/etc/greetd/cosmic-greeter.toml`, all 26 COSMIC + greetd packages installed, no `gnome-shell`/`gdm`/`mutter`/`alacritty`, `kdeconnect` + ufw ports 1714-1764, every `default/cosmic/` file deployed byte-identical into `~/.config/cosmic/`, `xkb_config` matching the installer keymap, session symlinks and exec bits, no `gnomarchy` strings in `/usr/local/bin` or `$HOME`, `.git` checkout, `~/.config/cosmic-initial-setup-done`, Brave Origin, WinBoat, LazyVim, Limine + blake2b hashes + fixed palette + Snapper + snapshot 1.
- **Session verification** (`iso/tests/verify-session.sh`, inside a real greetd autologin COSMIC session): `cosmic-comp`, `cosmic-panel`, and `cosmic-settings-daemon` running; no shortcut/system_actions RON parse errors in the journal; every Cosmarchy custom shortcut absent from COSMIC `defaults`; `autotile = true` and `autotile_behavior = PerWorkspace`; `xkb_config` layout matching the installer; `xdg-desktop-portal-cosmic` answering on the session D-Bus; timezone; snapper + `snap-pac` + Limine hashes + COSMIC Dark palette; WinBoat prerequisites; and handover to the snapshot boot.
- **Third boot, from a snapshot**: boots the snapshot in a tmpfs overlay, confirms `cosmic-comp` and the snapshot notification ran, confirms `cosmarchy-boot guard` and pacman refuse transactions, runs `cosmarchy snapshot restore`, and checks `@restore-backup-*`, `@`'s parent UUID, and that overlay writes never touched the snapshot.

Not covered by CI:

- Booting in BIOS mode (offline checks only: `limine-bios.sys` on the ESP and MBR boot code).
- An encrypted boot (no passphrase entry).
- The interactive gum screens and `cosmic-initial-setup` wizard.

Cut a release only from a commit where this job is green.

---

## 1. Syntax & Static Analysis Verification

```bash
# Verify syntax of all shell scripts
find . -type f -name "*.sh" -exec bash -n {} +
find bin/ -type f -exec bash -n {} +

# Run the full fast unit suite + shellcheck in Arch
docker run --rm -v "$PWD:/w" -w /w archlinux:latest bash iso/tests/unit.sh --deps
```

---

## 2. Virtual Machine Testing (QEMU / KVM)

### Prerequisites
```bash
# Arch Linux host
sudo pacman -S qemu-desktop edk2-ovmf virt-manager

# Ubuntu/Debian host
sudo apt install qemu-system-x86 ovmf
```

### Steps
1. **Build the Live ISO**:
   ```bash
   sudo ./iso/builder/build-iso.sh
   ```
2. **Launch QEMU with UEFI Boot**:
   ```bash
   ./run-vm.sh out/cosmarchy-linux-*.iso
   ```
3. **Verify Installer Workflow**:
   - Choose `/dev/vda`, fill the form (keyboard layout, user, password, hostname, timezone, optional LUKS2), review the summary, and watch all seven stages complete.
   - Verify Btrfs subvolumes (`@`, `@home`, `@snapshots`, `@var_log`, `@var_cache`) and Limine installation.
4. **Reboot into Installed System**:
   ```bash
   ./run-vm.sh
   ```
   - Verify `cosmic-greeter` (via `greetd`) starts and logs into the COSMIC Wayland session.
   - On an interactive install, complete `cosmic-initial-setup` on first login.

---

## 3. Desktop Environment & Functional Verification

Once logged into the COSMIC desktop:

1. **Test Auto-Tiling**:
   - `cosmarchy tiling status` reports `Tiling: on (COSMIC autotile)` and `autotile_behavior: PerWorkspace`.
   - Open two terminals with <kbd>Super</kbd> + <kbd>Return</kbd>; confirm they tile automatically.
   - Press <kbd>Super</kbd> + <kbd>Y</kbd> to toggle tiling for the active workspace, and <kbd>Super</kbd> + <kbd>G</kbd> to float a window.
2. **Test Keybindings**:
   - <kbd>Super</kbd> + <kbd>Return</kbd>: opens COSMIC Terminal (`cosmic-term`).
   - <kbd>Super</kbd> + <kbd>E</kbd>: opens COSMIC Files (`cosmic-files`).
   - <kbd>Super</kbd> + <kbd>B</kbd>: opens Brave Origin.
   - <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>Space</kbd>: opens `cosmarchy-menu` in `cosmic-term`.
   - <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>/</kbd>: opens `cosmarchy-keybindings` in `cosmic-term`.
   - <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>M</kbd>: opens `cosmarchy-manual` in `cosmic-term`.
   - Confirm no `shortcuts custom config error` appears in `journalctl --user -b`.
3. **Test Screen Capture**:
   - <kbd>Print</kbd>: launches COSMIC Screenshot.
   - <kbd>Ctrl</kbd> + <kbd>Print</kbd>: launches `slurp` region selector into Satty; cancelling with <kbd>Esc</kbd> exits quietly.
   - `cosmarchy capture screen` writes into `~/Pictures/Screenshots/`.
4. **Test Voxtype**:
   - `which whisper-cli` resolves and `systemctl is-enabled ydotoold` reports enabled.
   - Press <kbd>Super</kbd> + <kbd>D</kbd>, speak, press again; confirm text is typed into the focused window.
5. **Test KDE Connect & WinBoat**:
   - Confirm `kdeconnect` is installed and `sudo ufw status` (or `/etc/ufw/user.rules`) includes ports `1714:1764` TCP/UDP.
   - Run `cosmarchy windows status` and confirm Docker is running and your user is in the `docker` group.
6. **Test Btrfs Snapshots & Limine**:
   ```bash
   cosmarchy snapshot create "Test Snapshot"
   cosmarchy snapshot list
   ```
   - Reboot: verify the COSMIC Dark Limine menu shows the snapshot under **Cosmarchy → Snapshots**.
   - Boot it, confirm the snapshot notification appears (clicking restore opens `cosmic-term -e cosmarchy snapshot restore`), then run `cosmarchy snapshot restore <n>` and reboot.

---

## 4. Migration Verification

```bash
cosmarchy migrate --list      # inspect applied / pending migrations
cosmarchy update              # pulls, refreshes boot tooling, applies pending migrations
```

On a fresh install the ledger is baselined by `install/post-install/migrations-baseline.sh`, so `cosmarchy migrate --list` reports zero pending immediately after installation.
