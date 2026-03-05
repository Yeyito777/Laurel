#!/bin/sh
# Laurel configuration
# Copy to ~/.config/laurel/config.sh and edit to match your setup.

# Recording
CAPTURE_TARGET=HDMI-1       # monitor name (run gpu-screen-recorder --list-capture-options)
BUFFER_DURATION=60          # seconds of replay buffer
FPS=60                      # recording framerate
CODEC=auto                  # auto, h264, hevc, av1 (auto picks best for your GPU)
ENCODER=auto                # auto (GPU with CPU fallback), cpu (force CPU encoding)
AUDIO_SOURCE=default_output # PipeWire/PulseAudio sink to capture

# Hotkey
HOTKEY_KEY=g                # X key name (passed to XStringToKeysym)
HOTKEY_MOD=super            # none, super, alt, ctrl, shift (combinable: super+shift)

# Server — REQUIRED: set these to your clip server
CLIP_SERVER=""              # SSH alias from ~/.ssh/config
CLIP_DIR=/srv/clips         # remote directory for clips
CLIP_DOMAIN=""              # your clip domain (e.g. clips.example.com)

# Notification
NOTIFY_CMD=notify-send      # swap for your own (e.g. a custom script)
