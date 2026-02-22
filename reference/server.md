# Server Setup

The clip server runs on kitsune (192.168.0.100 on LAN, kitsune.yeyito.dev over the internet). It serves clips over HTTPS with nginx.

## Components

### nginx

Serves `/srv/clips/` as static files. The server block configuration is at `/etc/nginx/sites-enabled/clips.yeyito.dev`.

After certbot runs, the live config is:

```nginx
server {
    server_name clips.yeyito.dev;
    root /srv/clips;
    index index.html;

    location / {
        try_files $uri $uri/ $uri/index.html =404;
    }

    location ~* \.(mp4|webm|mkv)$ {
        add_header Accept-Ranges bytes;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    location ~* \.(jpg|png)$ {
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    location ~ /\. {
        deny all;
    }

    listen 443 ssl;
    ssl_certificate /etc/letsencrypt/live/clips.yeyito.dev/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/clips.yeyito.dev/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}

server {
    listen 80;
    server_name clips.yeyito.dev;
    # Redirect HTTP → HTTPS
    return 301 https://$host$request_uri;
}
```

Key design decisions:
- **`try_files $uri $uri/ $uri/index.html`**: When you visit `/slug/`, nginx serves `/srv/clips/slug/index.html`
- **Cache headers on video/image**: Clips are immutable (the slug is unique), so aggressive caching is safe. `max-age=31536000` (1 year) + `immutable` tells browsers and CDNs to never re-fetch.
- **`Accept-Ranges bytes`** on video files: Enables seeking in the browser video player without downloading the entire file first.
- **Deny dotfiles**: Prevents access to any hidden files that might end up in `/srv/clips/`.

### Arch nginx directory layout

Arch's default nginx.conf doesn't include `sites-available`/`sites-enabled`. The install script adds:

```nginx
include /etc/nginx/sites-enabled/*;
```

to the `http {}` block in `/etc/nginx/nginx.conf`, then symlinks our config:

```
/etc/nginx/sites-available/clips.yeyito.dev    # the file
/etc/nginx/sites-enabled/clips.yeyito.dev      # symlink to above
```

### TLS (certbot)

Let's Encrypt certificate managed by certbot with the nginx plugin. certbot modifies the nginx config in-place to add SSL directives.

```sh
# Initial setup (already done)
sudo certbot --nginx -d clips.yeyito.dev --non-interactive --agree-tos --email <email>

# Manual renewal test
sudo certbot renew --dry-run

# Auto-renewal timer
systemctl status certbot-renew.timer
```

Certificate location:
- Cert: `/etc/letsencrypt/live/clips.yeyito.dev/fullchain.pem`
- Key: `/etc/letsencrypt/live/clips.yeyito.dev/privkey.pem`
- Expires: every 90 days, auto-renewed by the `certbot-renew.timer` systemd timer

### ffmpeg

Used by `laurel-clip` (via SSH) to generate thumbnails on the server:

```sh
ffmpeg -y -i <clip.mp4> -vframes 1 -q:v 2 <thumb.jpg>
```

- `-vframes 1`: Extract only the first frame
- `-q:v 2`: JPEG quality (2 = high quality, small file)
- Runs on the server to avoid transferring the thumbnail separately

## Clip directory structure

```
/srv/clips/
├── 20260221-124305-a8d2dcab/
│   ├── index.html                    # ~2KB, generated from template
│   ├── Replay_2026-02-21_12-43-05.mp4  # the clip
│   └── thumb.jpg                     # ~200KB first-frame thumbnail
├── 20260222-183012-f4e1b9c3/
│   ├── index.html
│   ├── Replay_2026-02-22_18-30-12.mp4
│   └── thumb.jpg
└── ...
```

Ownership: `yeyito:yeyito` (the SCP user). nginx runs as `http` user but can read world-readable files (the `chmod 644` in laurel-clip ensures this).

## Port forwarding

The Arris router forwards:
- Port 80 (TCP) → 192.168.0.100:80
- Port 443 (TCP) → 192.168.0.100:443
- Port 48222 (TCP) → 192.168.0.100:22 (SSH, pre-existing)

## Disk usage

Rough estimates per clip (1080p 60fps, 60 second buffer):
- MP4: ~30-80MB depending on content complexity
- Thumbnail: ~100-300KB
- HTML: ~2KB

At 10 clips/day: ~500MB-800MB/day, ~15-24GB/month.

To clean old clips:

```sh
# Delete clips older than 30 days
ssh kitsune "find /srv/clips -maxdepth 1 -type d -mtime +30 -exec rm -rf {} +"
```

## Install / Uninstall

```sh
# Install (run on kitsune or pipe via SSH)
ssh kitsune 'bash -s' < server/install.sh

# Uninstall (preserves clips)
ssh kitsune 'bash -s' < server/uninstall.sh
```
