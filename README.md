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

- `opencode` v2 (the managed background service) for the account that runs `opc`
- `bash`, `curl`, `ss` (iproute2) or `lsof`, `ip`
- Optional: `cloudflared` (only for `--cloudflared`)
- Optional: `timeout`/`gtimeout` (CLI calls fall back to no timeout when absent)

## Install

```sh
git clone https://github.com/aungkyawkyawsoe/opc.git
cd opc
./install.sh
```

As root, `install.sh` installs to `/usr/local/bin`; otherwise to `~/.local/bin`. Pass a directory to override:

```sh
./install.sh /usr/local/bin
```

## Commands

```sh
opc start                  # ensure service + tunnel, print table and login link
opc start --qr             # also print a scannable QR for the mobile app
opc start --lan            # bind the service to 0.0.0.0 (restarts it)
opc start --port 5000      # use a specific service port (restarts it)
opc start --port auto      # allocate a new instance on the next free port

opc qr                     # fresh one-time link + QR for the OpenCode app
opc link                   # fresh one-time link only
opc status                 # state + cached link TTL, no changes
opc doctor                 # diagnostics: CLI, version, port ownership, network
opc restart                # new link (OpenTunnel) / restart tunnel (cloudflared)
opc stop                   # disable remote access (restarts local service)
opc stop --all             # disable remote access and stop the service
opc logs                   # follow the tunnel or service log
```

Options: `--cloudflared`, `--tunnel <opentunnel|cloudflared>`, `--protocol <auto|http2|quic>`, `--timeout <seconds>`, `--port <port|auto>`, `--lan`, `--no-link`, `--qr`, `--no-qr`, `--all`.

## Multiple accounts, ports, and machines

`opc` always manages the OpenCode service of the **current account** (it uses that account's `~/.config/opencode` state). Install and run it as the account that owns the service.

- **Root / another account on the same box**: if the default port `49374` is already owned by a different account, `opc start` automatically moves to the next free port, persists it with `opencode service set port`, and prints the new port. You can also be explicit: `opc start --port 49375`.
- **Several instances for one account**: give each one its own port (`--port 49376`) and, if you need separate config/data, separate OpenCode directories:
  ```sh
  OPENCODE_CONFIG_DIR=~/.config/opencode-a \
  XDG_DATA_HOME=~/.local/share/opencode-a \
  XDG_STATE_HOME=~/.local/state/opencode-a \
  opc start --port 49376
  ```
- **Servers**: install system-wide as root (`./install.sh` → `/usr/local/bin`), then run `opc start` over SSH. The table and login link are printed; scan the QR on the server terminal or use `opc qr`.
- **Across devices**: install `opc` on each machine; each copy manages that machine's OpenCode service. To add a phone/tablet/another browser, run `opc qr` and scan the new link. The OpenTunnel address stays the same across restarts.
- **No hangs**: every `opencode` CLI call has a timeout, so a port conflict or a stuck service discovery fails fast with a message instead of blocking.

## Troubleshooting

If `opc start` takes long:

1. `opc doctor` — shows the OpenCode CLI path/version, configured port, port ownership, OpenTunnel reachability, and health.
2. `opc start --no-link` — brings up the service and tunnel without minting a link. If the table appears in ~1s, only pairing was slow.
3. If `:49374` is owned by another account, `opc` moves automatically; force a port with `opc start --port 49375`.
4. If doctor says `opentunnel UNREACHABLE`, outbound HTTPS is blocked on that host; `--cloudflared` only works for API clients (the web UI needs SSE).

Progress messages go to stderr, so `opc start 2>/dev/null` prints only the table and link.

## Joining from a browser or the mobile app

`opc start` (on a terminal) prints the table, the login link, and a QR code. Either:

- open the link in a browser, or
- scan the QR with the OpenCode mobile app, or paste the link into its server address field.

The link is **single-use** and expires after **5 minutes**. A paired browser or app stays signed in for **30 days**. Run `opc qr` whenever you need a new link for another device.

## How it works

1. Resolve the instance port (`--port`, existing config, or auto-move off a port owned by another account).
2. Detect the managed service via `opencode service status`; start it if needed and wait for `/api/info`.
3. Apply `--lan` if requested.
4. Default backend: verify OpenTunnel remote access is enabled, then use `opencode pair --remote` for the public URL and pairing code.
5. Print the table, link, and (on a TTY) the QR.
6. Track the link TTL and tunnel state in `~/.local/state/opc/` (mode `0700`).

## Why OpenTunnel by default

Cloudflare quick tunnels **buffer `text/event-stream` responses**. OpenCode's web UI depends on `GET /api/event`, which then never delivers data through the tunnel, leaving the UI stuck on "Loading". `opc --cloudflared` is kept for API/non-streaming clients and prints a warning.

## Notes

- The pairing link is the credential; treat it like a password and keep it private.
- OpenTunnel is free to use and open source; self-hosting the relay is possible.
- `opc stop` disables remote access, which restarts the local OpenCode service briefly. Use `--all` to leave it stopped.
- Quick-tunnel URLs (`--cloudflared`) change on every restart; OpenTunnel addresses are stable.

## Uninstall

```sh
rm ~/.local/bin/opc   # or /usr/local/bin/opc
rm -rf ~/.local/state/opc
```
