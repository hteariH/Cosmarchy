# Screenshots

    Print            GNOME's own screenshot and recording tool
    Ctrl + Print     region capture straight into the Satty annotator

```bash
cosmarchy capture annotate
cosmarchy capture region
cosmarchy capture screen
```

Also under Capture in the command center.

## Where files go

`~/Pictures/Screenshots/`, named by timestamp. Captures are copied to the
clipboard as well as written to disk.

## Annotation

Satty opens with the grab and gives you arrows, boxes, text and blur. Save
writes into the screenshots folder; copy puts the annotated version on the
clipboard.

## Under the hood

`grim` and `slurp`, which are Wayland-native. Cancelling the region selection
is not an error - it exits quietly without writing a file.
