# DNS and Networking

How clips.yeyito.dev resolves to kitsune despite a dynamic IP.

## DNS records

```
clips.yeyito.dev    CNAME → kitsune.yeyito.dev    (record ID: 73211985, TTL: 300s)
kitsune.yeyito.dev  A     → <dynamic IP>           (record ID: 73089868, TTL: 300s)
```

The CNAME means clips.yeyito.dev always resolves to whatever IP kitsune.yeyito.dev points to. When the ISP changes kitsune's public IP, the DDNS system updates the A record and clips.yeyito.dev follows automatically — no extra config needed.

## DDNS

The ISP (Cable Onda) assigns a dynamic public IP via DHCP. A systemd timer on kitsune checks the IP every 5 minutes and updates the DNSimple A record if it changed.

```
kitsune timer (every 5 min)
    │
    ├─ curl https://ifconfig.me → current IP
    ├─ DNSimple API GET → recorded IP
    │
    └─ if different → DNSimple API PATCH → update A record
```

The DDNS infrastructure lives in `~/Workspace/DNSimple-config/`:
- `update-dns.sh`: The updater script, takes a config file as argument
- `configs/kitsune-yeyito-dev.env`: Config with zone, record ID, domain
- `dnsimple-ddns-kitsune-yeyito-dev.timer`: Systemd timer (5 min interval)

DNSimple API details:
- Account ID: 171315
- API base: `https://api.dnsimple.com/v2/171315`
- Auth: Bearer token (account access token)
- Zone: `yeyito.dev`

## DNS resolution path

```
User's browser
    │
    └─ DNS query: clips.yeyito.dev
        │
        └─ CNAME → kitsune.yeyito.dev
            │
            └─ A → <public IP>
                │
                └─ TCP to <public IP>:443
                    │
                    └─ Router NAT → 192.168.0.100:443
                        │
                        └─ nginx serves the clip
```

## Port forwarding

The Arris router forwards three ports to kitsune (192.168.0.100):

| External port | Internal port | Protocol | Purpose |
|---|---|---|---|
| 80 | 80 | TCP | HTTP (certbot ACME challenge + redirect to HTTPS) |
| 443 | 443 | TCP | HTTPS (clip serving) |
| 48222 | 22 | TCP | SSH (remote access, pre-existing) |

## Network path for clip upload

When laurel-clip uploads a clip, it uses the SSH alias from `~/.ssh/config`:

```
Host kitsune
    HostName kitsune.yeyito.dev
    User yeyito
    Port 48222

Host kitsune-local
    HostName 192.168.0.100
    User yeyito
```

The `CLIP_SERVER` config defaults to `kitsune` (internet route). When on the LAN, change it to `kitsune-local` in `~/.local/share/laurel/config.sh` for faster uploads (skips the public IP round-trip and uses port 22 directly).

## TTL considerations

Both DNS records have a 300s (5 minute) TTL. After an IP change:
- The DDNS timer detects and updates within 5 minutes
- DNS caches expire the old record within 5 minutes
- **Worst case**: ~10 minutes of downtime on IP change

## Adding to a new server

If moving clips to a different machine:

1. Update the `kitsune.yeyito.dev` A record (or point CNAME elsewhere)
2. Set up nginx + certbot on the new machine (use `server/install.sh`)
3. Forward ports 80/443 to the new machine
4. Update `CLIP_SERVER` in config.sh if the SSH alias changes
