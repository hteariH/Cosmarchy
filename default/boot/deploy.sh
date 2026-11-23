#!/bin/bash
# Installs Cosmarchy's boot tooling, root-owned, onto the system.
#
# Root must never execute scripts from a user's home, so everything that
# cosmarchy-boot, the snapper plugin and the pacman hooks run is copied out of
# the repository. Idempotent: the ISO installer runs it before installing the
# bootloader, install.sh runs it again, and so does every cosmarchy update.
#
#   sudo deploy.sh              onto /
#   DESTDIR=/tmp/x deploy.sh    onto a test tree
set -Eeuo pipefail

SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="${DESTDIR:-}"
[[ $EUID -eq 0 ]] || { echo "deploy.sh must run as root" >&2; exit 1; }

BOOT_CONF="$DEST/etc/cosmarchy/boot.conf"
if [[ ! -f "$BOOT_CONF" ]]; then
  echo "No $BOOT_CONF: this machine was not installed from the Cosmarchy ISO, so its bootloader is left alone."
  exit 0
fi

LIB_DIR="$DEST/usr/local/lib/cosmarchy/boot"
install -Dm755 "$SRC/cosmarchy-boot" "$LIB_DIR/cosmarchy-boot"
for f in "$SRC"/lib/*.sh; do
  install -Dm644 "$f" "$LIB_DIR/lib/${f##*/}"
done
install -Dm755 "$SRC/50-cosmarchy-boot" "$DEST/usr/lib/snapper/plugins/50-cosmarchy-boot"
install -Dm755 "$SRC/initcpio-post" "$DEST/etc/initcpio/post/cosmarchy-boot"
install -Dm644 "$SRC/00-cosmarchy-guard.hook" "$DEST/etc/pacman.d/hooks/00-cosmarchy-guard.hook"
install -Dm644 "$SRC/95-cosmarchy-boot.hook" "$DEST/etc/pacman.d/hooks/95-cosmarchy-boot.hook"
install -Dm644 "$SRC/95-cosmarchy-limine.hook" "$DEST/etc/pacman.d/hooks/95-cosmarchy-limine.hook"
install -Dm644 "$SRC/cosmarchy-overlay" "$DEST/etc/initcpio/install/cosmarchy-overlay"
install -Dm644 "$SRC/cosmarchy-boot-theme.path" "$DEST/etc/systemd/system/cosmarchy-boot-theme.path"
install -Dm644 "$SRC/cosmarchy-boot-theme.service" "$DEST/etc/systemd/system/cosmarchy-boot-theme.service"
install -Dm644 "$SRC/snapshot-notify.desktop" "$DEST/etc/xdg/autostart/cosmarchy-snapshot-notify.desktop"

# The initramfs. sd-encrypt only where there is something to open; plymouth
# after systemd and before the crypt hook, so the passphrase prompt is drawn.
encrypt=""
if grep -qx 'ENCRYPTED=1' "$BOOT_CONF"; then encrypt=" sd-encrypt"; fi
DROPIN="$DEST/etc/mkinitcpio.conf.d/cosmarchy.conf"
previous=""
if [[ -f "$DROPIN" ]]; then previous="$(<"$DROPIN")"; fi
mkdir -p "${DROPIN%/*}"
cat >"$DROPIN" <<EOF
# Written by Cosmarchy's default/boot/deploy.sh from /etc/cosmarchy/boot.conf.
HOOKS=(base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole block${encrypt} filesystems fsck cosmarchy-overlay)
EOF
# New HOOKS mean nothing until the images are rebuilt. On a first deploy the
# installer builds them right after this; on a later one (cosmarchy update)
# nothing else would until the next kernel upgrade. The post hook then
# regenerates the menu's hashes.
if [[ -z "$DEST" && -n "$previous" && "$previous" != "$(<"$DROPIN")" ]]; then
  echo "Initramfs hooks changed; rebuilding the images."
  mkinitcpio -P
fi

# The one file a user writes: cosmarchy-theme-set, as a member of wheel. It is
# parsed as data and never executed.
if [[ ! -f "$DEST/etc/cosmarchy/boot-theme.conf" ]]; then
  install -m664 -o root -g wheel /dev/null "$DEST/etc/cosmarchy/boot-theme.conf"
fi
chown root:wheel "$DEST/etc/cosmarchy/boot-theme.conf"
chmod 664 "$DEST/etc/cosmarchy/boot-theme.conf"

systemctl --root="${DEST:-/}" enable cosmarchy-boot-theme.path
# On a running system (cosmarchy update) systemd must reread the units just
# replaced. A chroot and a test tree have no systemd running to tell.
if [[ -z "$DEST" && -d /run/systemd/system ]]; then
  systemctl daemon-reload
fi
echo "Boot tooling deployed."
