# opc

One-stop remote access for [OpenCode](https://opencode.ai): ensure the service is up, expose it through a tunnel, mint a pairing link, and print everything as a table.

Defaults to **OpenTunnel**, OpenCode's built-in end-to-end encrypted tunnel, because it streams server-sent events and therefore serves the web and mobile apps correctly.

```
┌─────────────────┬────────────────────────────────────────────────────────────┐
│ OpenCode        │ up (pid 12345) on 0.0.0.0:49374                            │
│ Local           │ http://127.0.0.1:49374                                     │
│ LAN             │ http://192.168.1.10:49374                                  │
│ Public          │ https://abc123.xyz789.opentunnel.xyz                       │
│ Tunnel          │ OpenTunnel (managed by OpenCode)                           │
│ Login link      │ https://abc123.xyz789.opentunnel.xyz/auth/connect/…        │
│ Link TTL        │ 5 minutes - single use                                     │
│ Mobile app      │ OpenCode app - run: opc qr                                 │
│ Browser session │ 30 days per browser                                        │
└─────────────────┴────────────────────────────────────────────────────────────┘
```

## Requirements

- `opencode` v2 (the managed background service)
- `bash`, `curl`, `ss` (iproute2), `ip`
- Optional: `cloudflared` (only for `--cloudflared`)

## Install

```sh
git clone https://github.com/aungkyawkyawsoe/opc.git
cd opc
./install.sh
```

`install.sh` copies `opc` to `~/.local/bin` (override with the first argument). Make sure that directory is on your `PATH`.

## Commands

```sh
opc start                  # ensure service + tunnel, print table and login link
opc start --qr             # also print a scannable QR for the mobile app
opc start --lan            # bind the service to 0.0.0.0 (restarts it)
opc start --port 5000      # change the managed service port (restarts it)
opc start --cloudflared    # use a Cloudflare quick tunnel instead (see caveat)

opc qr                     # fresh one-time link + QR for the OpenCode app
opc link                   # fresh one-time link only
opc status                 # state + cached link TTL, no changes
opc restart                # new link (OpenTunnel) / restart tunnel (cloudflared)
opc stop                   # disable remote access (restarts local service)
opc stop --all             # disable remote access and stop the service
opc logs                   # follow the tunnel or service log
```

Options: `--cloudflared`, `--tunnel <opentunnel|cloudflared>`, `--protocol <auto|http2|quic>`, `--timeout <seconds>`, `--port <port>`, `--lan`, `--no-link`, `--qr`, `--no-qr`, `--all`.

## Joining from a browser or the mobile app

`opc start` (on a terminal) prints the table, the login link, and a QR code. Either:

- open the link in a browser, or
- scan the QR with the OpenCode mobile app, or paste the link into its server address field.

The link is **single-use** and expires after **5 minutes**. A paired browser or app stays signed in for **30 days**. Run `opc qr` whenever you need a new link for another device.

## How it works

1. Detect the managed service via `opencode service status`; start it if needed and wait for `/api/info`.
2. Optionally apply `--lan` / `--port` with `opencode service set`.
3. Default backend: verify OpenTunnel remote access is enabled, then use `opencode pair --remote` for the public URL and pairing code.
4. Print the table, link, and (on a TTY) the QR.
5. Track the link TTL and tunnel state in `~/.local/state/opc/` (mode `0700`).

## Why OpenTunnel by default

Cloudflare quick tunnels **buffer `text/event-stream` responses**. OpenCode's web UI depends on `GET /api/event`, which then never delivers data through the tunnel, leaving the UI stuck on "Loading". `opc --cloudflared` is kept for API/non-streaming clients and prints a warning.

## Notes

- The pairing link is the credential; treat it like a password and keep it private.
- OpenTunnel is free to use and open source; self-hosting the relay is possible.
- `opc stop` disables remote access, which restarts the local OpenCode service briefly. Use `--all` to leave it stopped.
- Quick-tunnel URLs (`--cloudflared`) change on every restart; OpenTunnel addresses are stable.

## Uninstall

```sh
rm ~/.local/bin/opc
rm -rf ~/.local/state/opc
```
