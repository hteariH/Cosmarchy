#!/bin/bash

cosmarchy_header "Configuring COSMIC Greeter (greetd)"

# Disable competing display managers if their unit files are installed.
# Missing units are expected and skipped; any other disable failure is surfaced.
for dm in gdm.service sddm.service lightdm.service greetd.service; do
  if [[ -e "/usr/lib/systemd/system/$dm" || -e "/etc/systemd/system/$dm" || -L "/etc/systemd/system/$dm" ]]; then
    if ! sudo systemctl disable "$dm"; then
      cosmarchy_warn "Could not disable $dm; continuing."
    fi
  fi
done

GREETER_CONF="/etc/greetd/cosmic-greeter.toml"
if [[ ! -f "$GREETER_CONF" ]]; then
  cosmarchy_warn "$GREETER_CONF missing; creating default greetd configuration."
  sudo mkdir -p /etc/greetd
  cat <<'EOF' | sudo tee "$GREETER_CONF" >/dev/null
[terminal]
vt = "1"

[general]
service = "login"

[default_session]
command = "cosmic-greeter-start"
user = "cosmic-greeter"
EOF
fi

# On an encrypted disk, configure greetd [initial_session] for seamless
# autologin into the COSMIC session after LUKS unlock.
# The ISO installer opens root from the kernel command line (rd.luks.name) so
# there is no /etc/crypttab; it records encryption in /etc/cosmarchy/boot.conf.
# Fall back to /etc/crypttab for online installs on pre-existing LUKS setups.
is_encrypted=0
if [[ -f /etc/cosmarchy/boot.conf ]] && grep -qx 'ENCRYPTED=1' /etc/cosmarchy/boot.conf; then
  is_encrypted=1
elif [[ -f /etc/crypttab ]] && grep -qv '^[[:space:]]*#' /etc/crypttab; then
  is_encrypted=1
fi

if ((is_encrypted)); then
  if ! grep -q '^\[initial_session\]' "$GREETER_CONF"; then
    echo "Encrypted disk detected. Enabling seamless auto-login via greetd [initial_session]..."
    cat <<EOF | sudo tee -a "$GREETER_CONF" >/dev/null

[initial_session]
command = "start-cosmic"
user = "$USER"
EOF
  fi
fi

# Determine which PAM service greetd uses for user sessions from cosmic-greeter.toml.
# Arch's cosmic-greeter currently reverts upstream's service="cosmic-greeter" to
# service="login" because it does not ship /etc/pam.d/cosmic-greeter; reading the
# config directly keeps PAM wiring aligned across Arch packaging changes.
pam_service="$(sed -nE 's/^[[:space:]]*service[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$GREETER_CONF" | head -n1)"
pam_service="${pam_service:-greetd}"

pam_targets=("/etc/pam.d/$pam_service")
if [[ "$pam_service" != "greetd" ]]; then
  pam_targets+=("/etc/pam.d/greetd")
fi

pam_wired=0
for pam_file in "${pam_targets[@]}"; do
  if [[ -f "$pam_file" ]]; then
    if ! grep -q "pam_gnome_keyring.so" "$pam_file"; then
      printf '\nauth       optional     pam_gnome_keyring.so\nsession    optional     pam_gnome_keyring.so auto_start\n' \
        | sudo tee -a "$pam_file" >/dev/null
    fi
    pam_wired=1
  fi
done

if ((pam_wired == 0)); then
  cosmarchy_warn "No target PAM file found for service '$pam_service'; gnome-keyring may not auto-unlock at login."
fi

# Enable COSMIC Greeter as the display manager (Arch patches cosmic-greeter.service
# with Alias=display-manager.service).
sudo systemctl enable --force cosmic-greeter.service

cosmarchy_step "COSMIC Greeter configured and enabled (PAM service: $pam_service)"
