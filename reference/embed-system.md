# Embed System

How clips appear when shared on Discord, Slack, Twitter, and other platforms.

## Open Graph tags

When you paste a clip URL into Discord or Slack, their servers fetch the page and read the Open Graph meta tags to build a rich embed. The clip template includes:

```html
<meta property="og:type" content="video.other">
<meta property="og:title" content="Clip — 20260221-124305-a8d2dcab">
<meta property="og:url" content="https://clips.yeyito.dev/20260221-124305-a8d2dcab">
<meta property="og:video" content="https://clips.yeyito.dev/20260221-124305-a8d2dcab/Replay_....mp4">
<meta property="og:video:type" content="video/mp4">
<meta property="og:video:width" content="1920">
<meta property="og:video:height" content="1080">
<meta property="og:image" content="https://clips.yeyito.dev/20260221-124305-a8d2dcab/thumb.jpg">
```

### What each tag does

| Tag | Purpose |
|---|---|
| `og:type` | Tells platforms this is a video, triggering video embed behavior |
| `og:video` | Direct URL to the MP4 file — platforms fetch and embed this |
| `og:video:type` | MIME type so platforms know it's a standard MP4 |
| `og:video:width/height` | Aspect ratio hint (1920x1080 = 16:9) |
| `og:image` | Thumbnail shown before the video loads / in notifications |
| `og:title` | Title displayed above the video embed |
| `og:url` | Canonical URL for the clip |

## Twitter/X cards

Twitter uses its own card system alongside Open Graph:

```html
<meta name="twitter:card" content="player">
<meta name="twitter:title" content="Clip — 20260221-124305-a8d2dcab">
<meta name="twitter:player" content="https://clips.yeyito.dev/20260221-124305-a8d2dcab">
<meta name="twitter:player:width" content="1920">
<meta name="twitter:player:height" content="1080">
<meta name="twitter:image" content="https://clips.yeyito.dev/20260221-124305-a8d2dcab/thumb.jpg">
```

The `player` card type tells Twitter to render an inline video player.

## Platform behavior

### Discord
- Fetches og:video URL and plays it inline in the chat
- Shows og:image as thumbnail before play
- Respects og:title for the embed header
- Video auto-plays on hover (desktop) or tap (mobile)

### Slack
- Shows og:image thumbnail with a play button
- Clicking opens the video inline
- og:title shows as the link unfurl title

### Twitter/X
- Uses twitter:card=player for inline playback
- Falls back to og: tags if twitter: tags are missing

### iMessage / SMS
- Shows og:image thumbnail with og:title
- Tapping opens the link in the browser

## Thumbnail

The thumbnail (`thumb.jpg`) is generated server-side by ffmpeg from the first frame of the clip:

```sh
ffmpeg -y -i <clip.mp4> -vframes 1 -q:v 2 <thumb.jpg>
```

This runs on kitsune during the upload step, so it's available immediately when platforms fetch the OG tags. Quality 2 produces a sharp JPEG at ~100-300KB.

## Template customization

The HTML template is at `~/.local/share/laurel/clip-template.html` (source: `server/clip-template.html`). It uses `{{PLACEHOLDER}}` tokens:

| Token | Replaced with | Example |
|---|---|---|
| `{{SLUG}}` | Clip slug | `20260221-124305-a8d2dcab` |
| `{{FILENAME}}` | MP4 filename | `Replay_2026-02-21_12-43-05.mp4` |
| `{{DOMAIN}}` | Clip domain | `clips.yeyito.dev` |
| `{{URL}}` | Full clip URL | `https://clips.yeyito.dev/20260221-124305-a8d2dcab` |

To customize the player page appearance, edit the `<style>` block. The default is a dark theme with monospace font, matching the terminal aesthetic.

## Debugging embeds

If embeds aren't showing up:

1. **Check OG tags**: `curl -s https://clips.yeyito.dev/<slug>/ | grep 'og:'`
2. **Discord cache**: Discord caches embeds aggressively. Append `?v=2` to the URL to bust the cache.
3. **Facebook debugger**: https://developers.facebook.com/tools/debug/ — parses OG tags and shows what platforms see
4. **Twitter card validator**: https://cards-dev.twitter.com/validator
5. **File permissions**: Ensure the MP4 and thumb.jpg are world-readable (`chmod 644`)
