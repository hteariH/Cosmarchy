# Backgrounds: provenance and licensing

## Cosmarchy does not redistribute Omarchy's wallpapers

Every theme's wallpapers are **downloaded onto your machine at install time**
from the upstream Omarchy repository. They are not committed to this repository
and they are not included in the Cosmarchy ISO.

This is a deliberate choice, not a size optimisation.

## Why

Omarchy is MIT-licensed, and that licence covers "the Software and associated
documentation files". MIT is a software licence, and a project can only license
what it owns.

For the bundled wallpapers specifically:

- Omarchy ships **no `NOTICE`, `CREDITS`, or attribution file**, and no source
  or author is recorded for any individual image.
- The only background source Omarchy names (in `manual/39-backgrounds.md`) is
  <https://github.com/dharmx/walls>, a personal collection published with
  **no licence at all**, aggregating third-party artwork.

Committing those files here would mean Cosmarchy's own `LICENSE` implicitly
claims rights over images whose authorship and terms are unknown — and Cosmarchy
publishes installable ISOs, which is redistribution at scale.

Downloading at install time keeps that boundary clean: the files are fetched by
the user's own machine, from the upstream project, and Cosmarchy neither ships
nor relicenses them.

## How it works

`install/backgrounds.manifest` pins the upstream repository and commit, and
records the git blob SHA-1 and size of all 92 wallpaper files.
[`bin/cosmarchy-backgrounds`](bin/cosmarchy-backgrounds) reads that manifest,
downloads each file from the pinned commit, and **verifies every file against
its recorded hash before installing it**. A file that fails verification is
discarded rather than installed.

```bash
cosmarchy backgrounds            # fetch (also repairs missing/corrupt files)
cosmarchy backgrounds --list     # show upstream pin and how many are installed
cosmarchy backgrounds --verify   # re-check installed files against the manifest
```

Files land in `/usr/share/backgrounds/cosmarchy/<theme>/`.

## Offline fallback

Every theme also ships a small generated SVG wallpaper in
`themes/<theme>/backgrounds/`. These are Cosmarchy's own, carry no third-party
rights, and are installed alongside the downloads. If a machine has no network,
or a download fails, each theme still has a working wallpaper.

## Using your own

Drop images into `~/.config/cosmarchy/backgrounds/<theme>/` and they take
precedence over both the downloaded and the bundled wallpapers:

```
~/.config/cosmarchy/backgrounds/nord/my-wallpaper.jpg
```

Resolution order, most specific first:

1. `~/.config/cosmarchy/backgrounds/<theme>/`
2. `/usr/share/backgrounds/cosmarchy/<theme>/` (downloaded)
3. `themes/<theme>/backgrounds/` (bundled SVG fallback)

## Updating the pin

To move to newer upstream wallpapers, regenerate the manifest against a new
commit and re-run `cosmarchy backgrounds`. The pin exists so that a given
Cosmarchy revision always fetches the same bytes.
