#!/bin/sh
# Install Laurel clip server on kitsune
# Run this ON the server (ssh kitsune, then run it), or via:
#   ssh kitsune 'bash -s' < server/install.sh
set -e

CLIP_DIR=/srv/clips
NGINX_CONF=clips.yeyito.dev
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Installing packages"
sudo pacman -S --needed --noconfirm nginx certbot certbot-nginx ffmpeg

echo "==> Creating clip directory"
sudo mkdir -p "$CLIP_DIR"
sudo chown "$(whoami):$(whoami)" "$CLIP_DIR"

echo "==> Installing nginx config"
sudo cp "${SCRIPT_DIR}/${NGINX_CONF}" /etc/nginx/sites-available/ 2>/dev/null || {
    # Arch uses /etc/nginx/conf.d/ or include from nginx.conf
    sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    sudo cp "${SCRIPT_DIR}/${NGINX_CONF}" /etc/nginx/sites-available/
    # Ensure nginx.conf includes sites-enabled
    if ! grep -q 'sites-enabled' /etc/nginx/nginx.conf; then
        sudo sed -i '/http {/a\    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
    fi
}
sudo ln -sf /etc/nginx/sites-available/"$NGINX_CONF" /etc/nginx/sites-enabled/

echo "==> Testing nginx config"
sudo nginx -t

echo "==> Starting nginx"
sudo systemctl enable --now nginx

echo "==> Setting up HTTPS with certbot"
echo "    Make sure ports 80 and 443 are forwarded to this machine first!"
echo "    Run: sudo certbot --nginx -d clips.yeyito.dev"

echo ""
echo "Done. Clip directory: $CLIP_DIR"
echo "Run certbot manually when port forwarding is ready."
