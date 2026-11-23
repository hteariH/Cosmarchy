#!/bin/bash

clear
echo -e "\033[1;32m"
cat <<'EOF'
  ██████╗ ███╗   ██╗ ██████╗ ███╗   ███╗ █████╗ ██████╗  ██████╗██╗  ██╗██╗   ██╗
 ██╔════╝ ████╗  ██║██╔═══██╗████╗ ████║██╔══██╗██╔══██╗██╔════╝██║  ██║╚██╗ ██╔╝
 ██║  ███╗██╔██╗ ██║██║   ██║██╔████╔██║███████║██████╔╝██║     ███████║ ╚████╔╝ 
 ██║   ██║██║╚██╗██║██║   ██║██║╚██╔╝██║██╔══██║██╔══██╗██║     ██╔══██║  ╚██╔╝  
 ╚██████╔╝██║ ╚████║╚██████╔╝██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╗██║  ██║   ██║   
  ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   
EOF
echo -e "\033[0m"
echo -e "\033[1;36mCosmarchy Installation Complete!\033[0m\n"
echo -e "Key features ready:"
echo -e "  - \033[1mCOSMIC + greetd\033[0m on pure Arch Linux"
echo -e "  - \033[1mAuto-Tiling\033[0m: enabled per workspace (\033[33mSuper + Y\033[0m to toggle, or \033[33mcosmarchy tiling\033[0m)"
echo -e "  - \033[1mDeveloper Terminal\033[0m: Press \033[33mSuper + Return\033[0m for COSMIC Terminal"
echo -e "  - \033[1mCosmarchy Launcher\033[0m: Press \033[33mSuper + Alt + Space\033[0m (or type \033[33mc \033[0m in COSMIC Launcher)"
echo -e "  - \033[1mBtrfs Rollbacks\033[0m: Run \033[33mcosmarchy snapshot create <name>\033[0m"
if [ -n "$COSMARCHY_CHROOT_INSTALL" ]; then
  echo -e "\n\033[1;32mInstallation fully completed! Preparing system reboot...\033[0m"
else
  echo -e "\nPlease reboot your machine to start your Cosmarchy session."
fi
