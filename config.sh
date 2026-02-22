#!/bin/sh
# Laurel configuration — all tunables in one place

# Recording
CAPTURE_TARGET=HDMI-1       # monitor name (run gpu-screen-recorder --list-capture-options)
BUFFER_DURATION=60          # seconds of replay buffer
FPS=60                      # recording framerate
CODEC=auto                  # auto, h264, hevc, av1 (auto picks best for your GPU)
AUDIO_SOURCE=default_output # PipeWire/PulseAudio sink to capture

# Hotkey
HOTKEY_KEY=F9               # X key name (passed to XStringToKeysym)
HOTKEY_MOD=none             # none, super, alt, ctrl, shift (combinable: super+shift)

# Local paths
CLIP_TMP_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/laurel"
LAUREL_DIR="${HOME}/.local/share/laurel"

# Server
CLIP_SERVER=kitsune         # SSH alias from ~/.ssh/config
CLIP_DIR=/srv/clips          # remote directory for clips
CLIP_DOMAIN=clips.yeyito.dev

# Notification
NOTIFY_CMD=notify-send      # swap for your own (e.g. st-notify $$)

# Template (resolved at install time, override if needed)
CLIP_TEMPLATE="${LAUREL_DIR}/clip-template.html"
