# Web Apps

Turn a website into a desktop application with its own window, icon and
profile.

```bash
cosmarchy webapp add "Linear" "https://linear.app"
cosmarchy webapp list
cosmarchy webapp remove "Linear"
```

Also under **Web App** in the command center.

## What you get

An isolated browser profile under `~/.local/share/cosmarchy/webapps/`, a
fetched favicon, and a `.desktop` entry under `~/.local/share/applications/`,
so the app shows up in COSMIC Launcher and COSMIC App Library and can be pinned
to the COSMIC dock like any native app. It does not share cookies with your
normal browsing.

## Good candidates

Anything you keep open all day and want in its own window rather than as a tab:
chat, mail, calendars, project trackers, AI assistants.
