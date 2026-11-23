# The Command Center

Press `Super + Alt + Space`, or run `cosmarchy menu` in any terminal.

The command center is a fast, text-only interactive menu built with `gum` and
launched inside `cosmic-term`. COSMIC Launcher (`Super`) handles opening
applications; the command center covers Cosmarchy's system actions:

    Keybindings   browse active COSMIC and Cosmarchy shortcuts
    Manual        browse and search this local manual
    Tiling        status, enable, disable, or toggle COSMIC auto-tiling
    Gaming        inspect the gaming stack status
    Web App       add, list, or remove isolated web apps
    Capture       annotate region (Satty), region to file, or full screen
    Snapshot      create, list, or restore Btrfs snapshots
    System        update everything, open COSMIC Settings, or show system info
    Power         lock, suspend, log out, reboot, or power off

Everything in the menu is also a plain CLI command:

```bash
cosmarchy menu
cosmarchy keybindings
cosmarchy manual
cosmarchy tiling toggle
cosmarchy capture annotate
cosmarchy snapshot list
```

Because it is plain terminal UI, it works identically inside COSMIC, on a
console TTY, and over SSH.
