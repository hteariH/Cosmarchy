#!/bin/bash
# deploy.sh onto a throwaway root. Needs root, which archlinux:latest has.
set -u
cd "$(dirname "$0")/../.." || exit 1
REPO="$PWD"
# shellcheck source=iso/tests/lib/assert.sh
source iso/tests/lib/assert.sh

D="$(mktemp -d)"
mkdir -p "$D/etc/cosmarchy"

# deploy.sh output goes to a log the test reads.
run_deploy() {
  env DESTDIR="$D" bash "$REPO/default/boot/deploy.sh" >"$D/deploy.log" 2>&1
}

echo "--- not installed from the ISO"
t_true "deploy succeeds without boot.conf" run_deploy
t_false "and installs nothing" test -e "$D/usr/local/lib/cosmarchy/boot/cosmarchy-boot"

echo "--- an encrypted ISO install"
printf 'DISK=/dev/vda\nESP_PART=2\nENCRYPTED=1\n' >"$D/etc/cosmarchy/boot.conf"
t_true "deploy succeeds" run_deploy
t_true "deploy reports completion" grep -qx 'Boot tooling deployed.' "$D/deploy.log"
for f in usr/local/lib/cosmarchy/boot/cosmarchy-boot usr/lib/snapper/plugins/50-cosmarchy-boot \
  etc/initcpio/post/cosmarchy-boot; do
  t_true "$f is executable" test -x "$D/$f"
done
for f in usr/local/lib/cosmarchy/boot/lib/common.sh usr/local/lib/cosmarchy/boot/lib/palette.sh \
  etc/pacman.d/hooks/00-cosmarchy-guard.hook etc/pacman.d/hooks/95-cosmarchy-boot.hook \
  etc/pacman.d/hooks/95-cosmarchy-limine.hook \
  etc/initcpio/install/cosmarchy-overlay etc/cosmarchy/boot-theme.conf \
  etc/xdg/autostart/cosmarchy-snapshot-notify.desktop; do
  t_true "$f is installed" test -f "$D/$f"
done
GUARD="$D/etc/pacman.d/hooks/00-cosmarchy-guard.hook"
for line in 'When = PreTransaction' 'AbortOnFail' 'Target = *' 'Exec = /usr/local/lib/cosmarchy/boot/cosmarchy-boot guard'; do
  t_true "the guard hook has: $line" grep -qxF "$line" "$GUARD"
done
t_false "theme path unit is not installed" test -e "$D/etc/systemd/system/cosmarchy-boot-theme.path"
t_false "theme service unit is not installed" test -e "$D/etc/systemd/system/cosmarchy-boot-theme.service"
t_true "the fixed COSMIC Dark palette is deployed" cmp -s "$REPO/default/boot/boot-theme.conf" "$D/etc/cosmarchy/boot-theme.conf"
t_eq "the theme file is mode 644" "$(stat -c '%a' "$D/etc/cosmarchy/boot-theme.conf")" "644"
t_true "sd-encrypt is in HOOKS" grep -q ' sd-encrypt ' "$D/etc/mkinitcpio.conf.d/cosmarchy.conf"
t_true "cosmarchy-overlay is in HOOKS" grep -q ' cosmarchy-overlay)' "$D/etc/mkinitcpio.conf.d/cosmarchy.conf"
t_false "no autostart phase (CLAUDE.md)" grep -q X-GNOME-Autostart-Phase "$D/etc/xdg/autostart/cosmarchy-snapshot-notify.desktop"

echo "--- a second run keeps the palette and follows boot.conf"
echo 'BACKGROUND=123456' >"$D/etc/cosmarchy/boot-theme.conf"
sed -i 's/ENCRYPTED=1/ENCRYPTED=0/' "$D/etc/cosmarchy/boot.conf"
t_true "second deploy succeeds" run_deploy
t_true "the existing palette file is kept" grep -qx 'BACKGROUND=123456' "$D/etc/cosmarchy/boot-theme.conf"
t_false "sd-encrypt is gone on an unencrypted install" grep -q sd-encrypt "$D/etc/mkinitcpio.conf.d/cosmarchy.conf"

rm -rf "$D"
t_done
