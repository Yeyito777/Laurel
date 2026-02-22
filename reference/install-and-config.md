# Install, Uninstall, and Configuration

## Fresh install

### Local (daily driver)

```sh
cd ~/Workspace/Laurel
./install.sh
```

This:
1. Installs `gpu-screen-recorder` via pacman
2. Compiles `laurel-hotkey` from C source
3. Copies `laurel-replay`, `laurel-clip`, and `laurel-hotkey` to `~/.local/bin/`
4. Copies `config.sh` and `clip-template.html` to `~/.local/share/laurel/`
5. Installs and enables the `laurel-replay.service` systemd user service

The hotkey (default Super+G) is handled by `laurel-hotkey` — no dwm configuration needed.

### Server (kitsune)

Either SSH in and run the script directly, or pipe it:

```sh
ssh kitsune 'bash -s' < server/install.sh
```

This:
1. Installs nginx, certbot, certbot-nginx, ffmpeg
2. Creates `/srv/clips/` owned by your user
3. Installs the nginx server block and enables the service
4. Prints instructions for running certbot

After the server is set up and ports 80/443 are forwarded:

```sh
ssh kitsune "sudo certbot --nginx -d clips.yeyito.dev --non-interactive --agree-tos --email <email>"
ssh kitsune "sudo systemctl enable --now certbot-renew.timer"
```

## Uninstall

### Local

```sh
cd ~/Workspace/Laurel
./uninstall.sh
```

Stops the service, removes scripts, binary, and data. Does NOT remove gpu-screen-recorder.

### Server

```sh
ssh kitsune 'bash -s' < server/uninstall.sh
```

Removes the nginx config. Does NOT delete `/srv/clips/` (your clips are preserved) or uninstall packages.

## Configuration

All config lives in a single file. The installed copy (the one that matters at runtime) is:

```
~/.local/share/laurel/config.sh
```

The source copy is `~/Workspace/Laurel/config.sh`. After editing the source, re-run `install.sh` or manually copy:

```sh
cp ~/Workspace/Laurel/config.sh ~/.local/share/laurel/config.sh
```

Then restart the replay buffer to pick up changes:

```sh
laurel-replay stop && laurel-replay start
# or
systemctl --user restart laurel-replay
```

### Config variables

```sh
# Recording
CAPTURE_TARGET=HDMI-1       # monitor to capture
BUFFER_DURATION=60          # replay buffer seconds
FPS=60                      # recording framerate
CODEC=auto                  # video codec (auto, h264, hevc, av1)
AUDIO_SOURCE=default_output # PipeWire/PulseAudio sink

# Hotkey
HOTKEY_KEY=g                # X key name (passed to XStringToKeysym)
HOTKEY_MOD=super            # super, alt, ctrl, shift (combinable: super+shift)

# Local paths
CLIP_TMP_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/laurel"
LAUREL_DIR="${HOME}/.local/share/laurel"

# Server
CLIP_SERVER=kitsune         # SSH alias
CLIP_DIR=/srv/clips         # remote clip directory
CLIP_DOMAIN=clips.yeyito.dev

# Notification
NOTIFY_CMD=notify-send      # notification command

# Template
CLIP_TEMPLATE="${LAUREL_DIR}/clip-template.html"
```

### Common config changes

**Change buffer to 30 seconds:**
```sh
BUFFER_DURATION=30
```

**Use a different monitor:**
```sh
# List options first
gpu-screen-recorder --list-capture-options
# Then set
CAPTURE_TARGET=DP-1
```

**Upload via LAN instead of internet:**
```sh
CLIP_SERVER=kitsune-local
```

**Use custom notification:**
```sh
NOTIFY_CMD="st-notify $$"
```

**Force H.264 codec:**
```sh
CODEC=h264
```

## File locations summary

| Path | Purpose | Machine |
|---|---|---|
| `~/Workspace/Laurel/` | Source / development | local |
| `~/.local/bin/laurel-replay` | Installed replay controller | local |
| `~/.local/bin/laurel-clip` | Installed upload hook | local |
| `~/.local/bin/laurel-hotkey` | Installed hotkey listener (compiled C binary) | local |
| `~/.local/share/laurel/config.sh` | Runtime config | local |
| `~/.local/share/laurel/clip-template.html` | HTML template | local |
| `~/.local/share/laurel/replay.pid` | gpu-screen-recorder PID (auto-managed) | local |
| `~/.local/share/laurel/hotkey.pid` | laurel-hotkey PID (auto-managed) | local |
| `~/.config/systemd/user/laurel-replay.service` | Systemd service | local |
| `~/.cache/laurel/` | Local clip cache (XDG_CACHE_HOME) | local |
| `/etc/nginx/sites-enabled/clips.yeyito.dev` | nginx config | kitsune |
| `/etc/letsencrypt/live/clips.yeyito.dev/` | TLS certificates | kitsune |
| `/srv/clips/` | Clip storage | kitsune |
