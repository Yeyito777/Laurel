# Upload Pipeline

How clips get from your machine to a shareable URL.

## laurel-clip

The `laurel-clip` script is the `-sc` hook called by gpu-screen-recorder after saving a clip. It receives two arguments:

```
laurel-clip <filepath> <type>
```

- `filepath`: absolute path to the saved MP4 (e.g. `~/.cache/laurel/Replay_2026-02-21_12-42-04.mp4`)
- `type`: one of `regular`, `replay`, `screenshot`

## Step-by-step flow

### 1. Slug generation

```sh
SLUG="$(date +%Y%m%d-%H%M%S)-$(od -An -tx1 -N4 /dev/urandom | tr -d ' \n')"
```

Produces a slug like `20260221-124305-a8d2dcab`. The timestamp prefix makes clips sortable; the random suffix prevents collisions if two clips are saved in the same second.

`od` is used instead of `xxd` because `xxd` is not installed by default on minimal Arch systems. `od -An -tx1 -N4` reads 4 bytes from `/dev/urandom` and prints them as hex without address prefix.

### 2. HTML generation

The clip template (`~/.local/share/laurel/clip-template.html`) is a static HTML file with `{{PLACEHOLDER}}` tokens. `sed` replaces them:

```sh
sed -e "s|{{SLUG}}|${SLUG}|g" \
    -e "s|{{FILENAME}}|${FILENAME}|g" \
    -e "s|{{DOMAIN}}|${CLIP_DOMAIN}|g" \
    -e "s|{{URL}}|${URL}|g" \
    "$CLIP_TEMPLATE" > "$TMPHTML"
```

The template includes:
- HTML5 `<video>` element with autoplay, loop, controls
- Open Graph meta tags for Discord/Slack embeds (`og:video`, `og:image`, etc.)
- Twitter player card meta tags
- Download link
- Minimal dark CSS

### 3. Upload

Three SSH commands handle the upload:

```sh
# Create the clip directory on the server
ssh "$CLIP_SERVER" "mkdir -p '${CLIP_DIR}/${SLUG}'"

# Upload the video file and HTML page
scp -q "$CLIP_FILE" "${CLIP_SERVER}:${CLIP_DIR}/${SLUG}/${FILENAME}"
scp -q "$TMPHTML" "${CLIP_SERVER}:${CLIP_DIR}/${SLUG}/index.html"

# Fix permissions (scp inherits umask, which may be restrictive)
ssh "$CLIP_SERVER" "chmod 644 '${CLIP_DIR}/${SLUG}'/*"
```

The `CLIP_SERVER` variable refers to an SSH alias defined in `~/.ssh/config` (default: `kitsune`). Authentication is key-based (ed25519).

### 4. Thumbnail generation

```sh
ssh "$CLIP_SERVER" "ffmpeg -y -i '...' -vframes 1 -q:v 2 '...thumb.jpg' 2>/dev/null"
```

ffmpeg extracts the first frame of the video as a JPEG thumbnail on the server. This is used by Open Graph `og:image` tags so Discord and other platforms show a preview image before the video loads.

### 5. Clipboard

```sh
printf '%s' "$URL" | xclip -selection clipboard
```

The full HTTPS URL is copied to the X clipboard. After saving a clip, you can immediately Ctrl+V the link anywhere.

### 6. Notification

```sh
$NOTIFY_CMD "Clip uploaded" "$URL"
```

Default is `notify-send`. Can be swapped to any command in `config.sh` (e.g. a custom st-notify call).

## Directory structure on server

Each clip creates one directory:

```
/srv/clips/<slug>/
├── index.html                      # video player page with OG tags
├── Replay_<timestamp>.mp4          # the actual clip
└── thumb.jpg                       # first-frame thumbnail
```

## Timing

The full pipeline from hotkey press to link in clipboard takes roughly:
- ~1s for gpu-screen-recorder to flush the buffer to disk
- ~1-5s for SCP upload (depends on clip size and connection speed)
- ~1s for ffmpeg thumbnail extraction
- Total: **3-7 seconds** on a LAN connection

## SSH connection optimization

If latency matters, you can add to `~/.ssh/config`:

```
Host kitsune-local
    HostName 192.168.0.100
    User yeyito
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
```

This keeps a persistent SSH connection open, eliminating the ~200ms TCP+SSH handshake on each of the 4 SSH/SCP commands. Create the socket dir: `mkdir -p ~/.ssh/sockets`.
