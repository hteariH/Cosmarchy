# Updates

```bash
cosmarchy update
```

This does five things: updates Arch packages, updates AUR packages, pulls the
Cosmarchy configuration, refreshes the root-owned boot tooling, and applies any
migrations that came with it.

It reports which stages failed and exits non-zero if any did. A green tick
means every stage actually succeeded.

## Migrations

Editing a file in the Cosmarchy repository only affects new installs. Machines
that are already running need a migration - a timestamped script, applied
exactly once, recorded in:

    ~/.local/state/cosmarchy/migrations.log

```bash
cosmarchy migrate --list
cosmarchy migrate
```

`cosmarchy update` runs pending migrations automatically after the pull. This
is how configuration changes reach a machine that was installed months ago.

## Writing one

Add `migrations/<YYYY-MM-DD-HHMM>-<slug>.sh`. It must be idempotent: it may run
on a machine in any prior state, and re-running must not double-apply.

## If the pull fails

The Cosmarchy checkout is deployed, not authored. If you have local changes
they are stashed automatically and the command tells you how to get them back:

```bash
git -C ~/.local/share/cosmarchy stash pop
```

## Rolling back an update

See `cosmarchy manual 12`.
