# Screenshots

    Print            COSMIC's built-in screenshot tool (cosmic-screenshot)
    Ctrl + Print     region capture straight into the Satty annotator

```bash
cosmarchy capture annotate
cosmarchy capture region
cosmarchy capture screen
```

Also available in COSMIC Launcher via `c cap` (or `cosmarchy menu` in a TTY).

## Where files go

`~/Pictures/Screenshots/`, named by timestamp. Captures are copied to the
clipboard (`wl-copy`) as well as written to disk.

## Annotation

Satty opens with the grab and gives you arrows, boxes, text, and blur. Save
writes into the screenshots folder; copy puts the annotated version on the
clipboard.

## Under the hood

`grim` and `slurp`, which are Wayland-native, with `cosmic-screenshot` as
fallback. Cancelling the region selection is not an error — it exits quietly
without writing a file.
