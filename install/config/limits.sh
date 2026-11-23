#!/bin/bash

cosmarchy_header "Optimizing System Limits & Kernel Watchers"

# Increase inotify file watchers for heavy developer projects (Next.js, Rails, Vite)
sudo mkdir -p /etc/sysctl.d
cat <<EOF | sudo tee /etc/sysctl.d/99-cosmarchy-limits.conf >/dev/null
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 8192
fs.file-max = 2097152
EOF
sudo sysctl --system >/dev/null 2>&1 || true

# Increase open file descriptor security limits
sudo mkdir -p /etc/security/limits.d
cat <<EOF | sudo tee /etc/security/limits.d/99-cosmarchy.conf >/dev/null
* soft nofile 65536
* hard nofile 1048576
* soft memlock unlimited
* hard memlock unlimited
EOF

cosmarchy_step "System limits and inotify watchers expanded"
