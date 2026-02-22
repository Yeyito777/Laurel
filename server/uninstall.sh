#!/bin/sh
# Uninstall Laurel clip server from kitsune
set -e

NGINX_CONF=clips.yeyito.dev

echo "==> Removing nginx config"
sudo rm -f /etc/nginx/sites-enabled/"$NGINX_CONF"
sudo rm -f /etc/nginx/sites-available/"$NGINX_CONF"
sudo nginx -t && sudo systemctl reload nginx

echo "==> Note: /srv/clips/ was NOT removed (your clips are still there)"
echo "==> Note: nginx, certbot, ffmpeg were NOT uninstalled"
echo ""
echo "To fully remove clips: sudo rm -rf /srv/clips"
echo "To remove packages: sudo pacman -Rs nginx certbot certbot-nginx"
echo "Done."
