/**
 * Cosmarchy — interactive client application
 *
 * Dictation sequence illustration and the CLI playground. Every string in
 * CLI_ENTRIES is what the corresponding script in bin/ actually prints;
 * commentary goes in the separate `note` field so the two are never confused.
 */
(function () {
  'use strict';

  // --- Dictation sequence ---------------------------------------------------
  function setupVoxtypeSequence() {
    const btn = document.getElementById('simulateVoiceBtn');
    const statusLabel = document.getElementById('voiceStatusLabel');
    const transcript = document.getElementById('voiceTranscript');
    const bars = document.querySelectorAll('#audioWaveVisualizer .audio-bar');
    if (!btn) return;

    let running = false;

    btn.addEventListener('click', () => {
      if (running) return;
      running = true;

      if (statusLabel) {
        statusLabel.textContent = 'RECORDING';
        statusLabel.style.color = 'var(--accent)';
      }
      if (transcript) transcript.textContent = 'Recording. Press Super+D again to stop.';

      let count = 0;
      const interval = setInterval(() => {
        bars.forEach(bar => {
          bar.style.height = `${Math.floor(Math.random() * 42) + 8}px`;
        });
        count++;

        if (count > 16) {
          clearInterval(interval);
          bars.forEach((bar, i) => {
            const heights = [14, 24, 36, 48, 28, 18, 40, 30, 12];
            bar.style.height = `${heights[i % heights.length]}px`;
          });

          if (statusLabel) {
            statusLabel.textContent = 'TRANSCRIBING (whisper-cpp, CPU)';
            statusLabel.style.color = 'var(--text-muted)';
          }
          if (transcript) transcript.textContent = 'Running whisper-cpp on the recording...';

          setTimeout(() => {
            if (statusLabel) {
              statusLabel.textContent = 'TYPED INTO THE FOCUSED WINDOW';
              statusLabel.style.color = 'var(--color-green)';
            }
            if (transcript) {
              transcript.textContent =
                '"Roll back to the snapshot from before the kernel upgrade."';
            }
            running = false;
          }, 900);
        }
      }, 100);
    });
  }

  // --- CLI playground -------------------------------------------------------
  // `output` is verbatim; `note` is this site talking, not the script.
  const CLI_ENTRIES = {
    tiling: {
      cmd: 'cosmarchy tiling status',
      output: `Tiling: on (COSMIC autotile)
  autotile:          true
  autotile_behavior: PerWorkspace
  shortcut:          Super + Y (per-workspace toggle)

Switch with: cosmarchy tiling <enable|disable|toggle>`,
      note: 'Reads and atomically updates ~/.config/cosmic/com.system76.CosmicComp/v1/autotile; ' +
            'cosmic-comp picks up the change live.'
    },
    keybindings: {
      cmd: 'cosmarchy keybindings --list',
      output: `Cosmarchy Keybindings (COSMIC)

Cosmarchy & Custom Shortcuts
Super + Return                Terminal
Super + E                     Files
Super + D                     Voxtype AI Dictation
Ctrl + Print                  Annotate Screenshot
Super + Alt + Space           Cosmarchy Menu
Super + Alt + /               Cosmarchy Keybindings
Super + Alt + M               Cosmarchy Manual`,
      note: 'Reads /usr/share/cosmic/.../v1/defaults and ~/.config/cosmic/.../v1/custom directly. ' +
            'Every Cosmarchy binding uses a key COSMIC leaves free.'
    },
    snapshot: {
      cmd: 'cosmarchy snapshot create "Before the kernel upgrade"',
      output: `Creating Snapper root snapshot: Before the kernel upgrade
Snapshot created successfully.`,
      note: 'Snapper snapshots the root before and after every pacman transaction. ' +
            'Each snapshot appears in the COSMIC Dark Limine menu and boots with its own kernel; ' +
            'cosmarchy snapshot restore makes one the system. /home is a separate ' +
            'subvolume and is not part of a root snapshot.'
    },
    webapp: {
      cmd: 'cosmarchy webapp add Claude https://claude.ai',
      output: `Fetching icon for claude.ai...
✓ Web application 'Claude' created successfully!
  Location: /home/you/.local/share/applications/cosmarchy-webapp-claude.desktop
  URL:      https://claude.ai`,
      note: 'The app gets its own browser profile under ' +
            '~/.local/share/cosmarchy/webapps/claude/profile and appears automatically in COSMIC ' +
            'App Library and COSMIC Launcher.'
    },
    update: {
      cmd: 'cosmarchy update',
      output: `==> Updating Cosmarchy System Packages
==> Updating Cosmarchy Configurations
    Configuration updated
==> Updating Boot Tooling
    Boot menu regenerated

✓ System up to date!`,
      note: 'No set -e here on purpose: each stage may fail on its own and is ' +
            'recorded. Every stage reports what actually succeeded.'
    },
    windows: {
      cmd: 'cosmarchy windows status',
      output: `WinBoat:
  no    not installed (cosmarchy windows install)
Requirements:
  ok    KVM: /dev/kvm is usable
  ok    Docker: the service is running
  ok    Docker: compose is available
  ok    Docker: you is in the docker group
  ok    FreeRDP: xfreerdp3 is installed`,
      note: 'Opt-in. cosmarchy windows install takes winboat-bin from the AUR, or the ' +
            'checksum-pinned release AppImage; WinBoat then runs Windows in a ' +
            'container and opens its apps as ordinary windows.'
    }
  };

  function setupCliPlayground() {
    const tabs = document.querySelectorAll('.cli-tab');
    const cmdDisplay = document.getElementById('cliCmdDisplay');
    const outDisplay = document.getElementById('cliOutputDisplay');
    const noteDisplay = document.getElementById('cliNoteDisplay');
    const copyBtn = document.getElementById('cliCopyBtn');

    function show(key) {
      const entry = CLI_ENTRIES[key];
      if (!entry || !cmdDisplay || !outDisplay) return;
      cmdDisplay.textContent = entry.cmd;
      outDisplay.textContent = entry.output;
      if (noteDisplay) {
        noteDisplay.textContent = entry.note || '';
        noteDisplay.hidden = !entry.note;
      }
    }

    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        tabs.forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        show(tab.dataset.cmd);
      });
    });

    show('tiling');

    if (copyBtn && cmdDisplay) {
      copyBtn.addEventListener('click', () => copyText(cmdDisplay.textContent, copyBtn));
    }
  }

  // --- Copy helper ----------------------------------------------------------
  function copyText(text, el) {
    const orig = el.textContent;
    const notify = () => {
      el.textContent = 'Copied!';
      setTimeout(() => { el.textContent = orig; }, 1600);
    };

    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(notify).catch(() => fallbackCopy(text, notify));
    } else {
      fallbackCopy(text, notify);
    }
  }

  function fallbackCopy(text, cb) {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.focus();
    ta.select();
    try {
      document.execCommand('copy');
      if (cb) cb();
    } catch (e) {}
    document.body.removeChild(ta);
  }

  // --- Init -----------------------------------------------------------------
  document.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('[data-copy-cmd]').forEach(el => {
      el.addEventListener('click', () => copyText(el.getAttribute('data-copy-cmd'), el));
    });

    setupVoxtypeSequence();
    setupCliPlayground();
  });
})();
