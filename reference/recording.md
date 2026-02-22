# Recording Pipeline

How the replay buffer and clip saving work.

## gpu-screen-recorder

The core recording engine. It's a C program that uses VA-API (AMD/Intel) or NVENC (NVIDIA) for hardware-accelerated screen capture with near-zero CPU overhead.

### Replay mode

Laurel runs gpu-screen-recorder in **replay mode** (`-r` flag), which maintains a rolling buffer of the last N seconds in memory. Nothing is written to disk until a save is triggered.

The exact invocation (from `laurel-replay`):

```sh
gpu-screen-recorder \
    -w "$CAPTURE_TARGET" \    # monitor name, e.g. HDMI-1
    -f "$FPS" \               # framerate, e.g. 60
    -r "$BUFFER_DURATION" \   # buffer seconds, e.g. 60
    -a "$AUDIO_SOURCE" \      # audio sink, e.g. default_output
    -c mp4 \                  # container format
    -o "$CLIP_TMP_DIR" \      # output directory for saved clips
    -sc "$CLIP_HOOK"          # post-save script (laurel-clip)
```

### Saving a clip

When gpu-screen-recorder receives `SIGUSR1`, it:
1. Flushes the replay buffer to disk as `~/.cache/laurel/Replay_<timestamp>.mp4`
2. Calls the `-sc` script with two arguments: `<filepath> <type>`
   - `type` is one of: `regular`, `replay`, `screenshot`
   - For replay saves, type is always `replay`

### Codec selection

When `CODEC=auto`, gpu-screen-recorder picks the best codec your GPU supports. You can force a specific codec with `-k`:

| Value | Codec | Notes |
|---|---|---|
| `auto` | GPU's best | No `-k` flag passed |
| `h264` | H.264 | Universal compatibility, larger files |
| `hevc` | H.265/HEVC | Better compression, widely supported |
| `av1` | AV1 | Best compression, requires recent GPU |

### Listing available options

```sh
gpu-screen-recorder --list-capture-options    # monitors/windows
gpu-screen-recorder --list-audio-devices      # audio sinks
gpu-screen-recorder --info                    # codec support
```

## laurel-replay

Shell script wrapper around gpu-screen-recorder. Manages the process lifecycle.

### Subcommands

| Command | What it does |
|---|---|
| `laurel-replay start` | Launches gpu-screen-recorder in replay mode and laurel-hotkey listener. Writes PIDs to `~/.local/share/laurel/{replay,hotkey}.pid` |
| `laurel-replay stop` | Sends SIGTERM to both processes, removes PID files |
| `laurel-replay save` | Sends SIGUSR1 to save the current buffer (manual trigger, the hotkey does this automatically) |
| `laurel-replay status` | Reports status of both gpu-screen-recorder and laurel-hotkey |

### Process management

PIDs are stored at `~/.local/share/laurel/replay.pid` (gpu-screen-recorder) and `~/.local/share/laurel/hotkey.pid` (laurel-hotkey). The script checks `kill -0` to verify each process is alive before operations. If a PID file exists but the process is dead, the file is cleaned up.

### Config resolution

Both scripts look for config in this order:
1. `$LAUREL_CONFIG` environment variable (set by the systemd service)
2. `~/.local/share/laurel/config.sh` (installed location)

Every config variable has a hardcoded default fallback so the scripts work even without a config file.

## systemd integration

`laurel-replay.service` is a user service that auto-starts the replay buffer on login:

```ini
[Unit]
Description=Laurel replay buffer (GPU Screen Recorder)
After=graphical-session.target

[Service]
Type=forking
ExecStart=%h/.local/bin/laurel-replay start
ExecStop=%h/.local/bin/laurel-replay stop
Environment=LAUREL_CONFIG=%h/.local/share/laurel/config.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
```

`Type=forking` because `laurel-replay start` backgrounds gpu-screen-recorder and exits. The `LAUREL_CONFIG` env var ensures the config is found regardless of working directory.

### Manual control

```sh
systemctl --user start laurel-replay    # start
systemctl --user stop laurel-replay     # stop
systemctl --user status laurel-replay   # check
journalctl --user -u laurel-replay      # logs
```

## Hotkey (laurel-hotkey)

The save trigger uses `laurel-hotkey`, a small C program that globally grabs a key combo via `XGrabKey`. It runs alongside gpu-screen-recorder, managed by `laurel-replay`.

```
laurel-hotkey <pidfile> [key] [modifier]
```

- `pidfile`: path to `replay.pid` (read on each keypress to get the gpu-screen-recorder PID)
- `key`: X key name passed to `XStringToKeysym` (default: `g`)
- `modifier`: `super`, `alt`, `ctrl`, `shift`, or combos like `super+shift` (default: `super`)

On keypress, it reads the PID from the pidfile and sends SIGUSR1. It grabs with NumLock/CapsLock/ScrollLock mask variants so the hotkey works regardless of lock state. Cleans up (ungrab + close display) on SIGTERM/SIGINT.

The hotkey is configured in `config.sh` via `HOTKEY_KEY` and `HOTKEY_MOD`. No dwm keybind is needed.

## Clip storage

Saved clips land in `~/.cache/laurel/` (or `$XDG_CACHE_HOME/laurel/`). They persist across reboots but are safe to delete — the authoritative copy lives on the server at `/srv/clips/<slug>/`.
