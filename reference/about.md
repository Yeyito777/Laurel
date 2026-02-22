# Laurel

Laurel is a self-hosted Medal.tv replacement for Linux. Press a hotkey, get a shareable clip link in your clipboard.

## Why

Medal.tv has no Linux support and no plans for it. Laurel replicates the core Medal workflow — always-on replay buffer, hotkey save, instant upload, shareable link — using only shell scripts, gpu-screen-recorder, nginx, and SSH. No Docker, no databases, no runtimes.

## How it works

```
gpu-screen-recorder (replay buffer, always running)
    │
    │  SIGUSR1 (triggered by Super+G via laurel-hotkey)
    ▼
clip saved to ~/.cache/laurel/Replay_<timestamp>.mp4
    │
    │  -sc hook fires laurel-clip
    ▼
laurel-clip:
    1. generates slug (20260221-124305-a8d2dcab)
    2. renders HTML page from template (video player + OG tags)
    3. scp clip + HTML + thumbnail to kitsune:/srv/clips/<slug>/
    4. copies https://clips.yeyito.dev/<slug> to clipboard
    5. fires notify-send
    │
    ▼
nginx on kitsune serves the clip page over HTTPS
    → Discord/Slack/Twitter embed the video via Open Graph tags
    → Direct link plays in any browser
```

## Architecture

Two machines, three components:

### Local machine (daily driver)
- **gpu-screen-recorder**: AMD/Intel/NVIDIA hardware-accelerated screen recorder. Runs in replay mode with a configurable rolling buffer (default 60s). Captures the monitor at 60fps into RAM. When it receives SIGUSR1, it dumps the buffer to an MP4 file and calls the `-sc` hook.
- **laurel-replay**: Shell script that manages both gpu-screen-recorder and laurel-hotkey processes. Subcommands: `start`, `stop`, `save`, `status`. The `save` subcommand sends SIGUSR1.
- **laurel-hotkey**: Small C program that uses `XGrabKey` to globally grab a hotkey (default Super+G). On keypress, reads the PID from the pidfile and sends SIGUSR1 to gpu-screen-recorder. Handles NumLock/CapsLock/ScrollLock mask variants. Managed by `laurel-replay` alongside the recorder.
- **laurel-clip**: Shell script called by gpu-screen-recorder's `-sc` hook after each save. Handles slug generation, HTML templating, SCP upload, clipboard copy, and notification.

### Remote server (kitsune)
- **nginx**: Serves `/srv/clips/` over HTTPS. Each clip lives in its own directory (`/srv/clips/<slug>/`) containing the MP4, an `index.html` with a video player and Open Graph meta tags, and a `thumb.jpg` thumbnail.
- **certbot**: Manages the Let's Encrypt TLS certificate for `clips.yeyito.dev`. Auto-renews via systemd timer.

### DNS
- `clips.yeyito.dev` is a CNAME pointing to `kitsune.yeyito.dev`
- `kitsune.yeyito.dev` is an A record managed by a DDNS timer (updates every 5 minutes via DNSimple API)
- This means clips.yeyito.dev automatically follows IP changes with no extra DDNS config

## File layout

```
~/Workspace/Laurel/              # source / development
├── config.sh                    # all tunables
├── laurel-replay                # replay buffer controller
├── laurel-clip                  # post-save upload hook
├── laurel-hotkey.c              # XGrabKey hotkey listener (C source)
├── Makefile                     # compiles laurel-hotkey
├── laurel-replay.service        # systemd user service
├── install.sh                   # local install script
├── uninstall.sh                 # local uninstall script
├── server/
│   ├── clip-template.html       # HTML template with OG tags
│   ├── clips.yeyito.dev         # nginx server block (pre-certbot)
│   ├── install.sh               # server install script
│   └── uninstall.sh             # server uninstall script
└── reference/                   # this documentation

~/.local/bin/                    # installed scripts + binary
├── laurel-replay
├── laurel-clip
└── laurel-hotkey

~/.local/share/laurel/           # installed data
├── config.sh
├── clip-template.html
├── replay.pid
└── hotkey.pid

~/.cache/laurel/                 # local clip cache (XDG_CACHE_HOME)

kitsune:/srv/clips/              # clip storage (server)
└── <slug>/
    ├── index.html
    ├── Replay_<timestamp>.mp4
    └── thumb.jpg
```

## Config

All tunables live in `config.sh`. Both `laurel-replay` and `laurel-clip` source it. The installed copy is at `~/.local/share/laurel/config.sh` — edit that one for runtime changes. Key values:

| Variable | Default | Purpose |
|---|---|---|
| `CAPTURE_TARGET` | `HDMI-1` | Monitor to capture (`gpu-screen-recorder --list-capture-options`) |
| `BUFFER_DURATION` | `60` | Seconds of replay buffer |
| `FPS` | `60` | Recording framerate |
| `CODEC` | `auto` | Video codec (auto, h264, hevc, av1) |
| `AUDIO_SOURCE` | `default_output` | PipeWire/PulseAudio sink |
| `HOTKEY_KEY` | `g` | X key name for XStringToKeysym |
| `HOTKEY_MOD` | `super` | Modifier: super, alt, ctrl, shift (combinable: super+shift) |
| `CLIP_SERVER` | `kitsune` | SSH alias for the server |
| `CLIP_DIR` | `/srv/clips` | Remote clip directory |
| `CLIP_DOMAIN` | `clips.yeyito.dev` | Domain for shareable links |
| `NOTIFY_CMD` | `notify-send` | Notification command |

## Dependencies

**Local**: gpu-screen-recorder, libX11, xclip, ssh, scp, od, sed, notify-send (or custom)

**Server**: nginx, certbot, certbot-nginx, ffmpeg
