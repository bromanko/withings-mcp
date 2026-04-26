# withings-mcp

Personal deployment wrapper for [`akutishevsky/withings-mcp`](https://github.com/akutishevsky/withings-mcp), an HTTP Model Context Protocol server for Withings health data.

This repo does not fork the upstream application code directly. Instead it:

- pins the upstream repo as a Nix flake input,
- applies a small local patch to remove the upstream Google Analytics tag from static pages,
- provides a Nix/direnv development shell with the tools needed to work on and deploy it,
- provides scripts and systemd/Caddy examples for deploying to a Hetzner host.

## Development environment

### Prerequisites

- [Nix](https://nixos.org/) with flakes enabled
- [direnv](https://direnv.net/) and ideally [nix-direnv](https://github.com/nix-community/nix-direnv)

Activate the shell:

```sh
direnv allow
```

or manually:

```sh
nix develop
```

The shell includes Bun, Node.js, TypeScript tooling, Supabase CLI, Hetzner `hcloud`, rsync/ssh, jj, Nix format/lint tools, and shell linters.

## Upstream source

The upstream source is pinned in `flake.lock` via the `withings-mcp-src` input. To materialize a writable local copy:

```sh
scripts/materialize-upstream
```

This creates `vendor/withings-mcp` from the pinned, patched source and runs `bun install --frozen-lockfile`. The `vendor/` copy is ignored and can be deleted/recreated at any time.

Useful commands:

```sh
make upstream    # create vendor/withings-mcp
make dev         # run upstream server with bun --hot
make typecheck   # run upstream TypeScript typecheck
make build       # build upstream Bun bundle locally
```

To update upstream later:

```sh
nix flake lock --update-input withings-mcp-src
scripts/materialize-upstream
```

## Local configuration

Copy upstream's environment template after materializing the source:

```sh
cp vendor/withings-mcp/.env.example vendor/withings-mcp/.env
```

At minimum, configure:

- `WITHINGS_CLIENT_ID`
- `WITHINGS_CLIENT_SECRET`
- `WITHINGS_REDIRECT_URI`
- `ENCRYPTION_SECRET`
- `SUPABASE_URL`
- `SUPABASE_SECRET_KEY`

Withings requires a publicly reachable OAuth callback URL. For local development, use a tunnel or a staging deployment and set the callback to `/callback`.

## Supabase

The upstream server currently uses Supabase for encrypted token/session storage and rate limiting. The dev shell includes `supabase`.

From the materialized upstream checkout:

```sh
cd vendor/withings-mcp
supabase link --project-ref <project-ref>
supabase db push
```

The deployment bundle includes upstream migrations under `supabase/migrations/` for reference, but applying migrations is still a separate operational step.

## Hetzner deployment

The deployment flow mirrors the simple release-directory style used in `~/Code/michael`:

1. Build a timestamped release locally from the pinned, patched upstream source.
2. Upload it to `/var/lib/withings-mcp/releases/<release-id>`.
3. Update `/var/lib/withings-mcp/current`.
4. Restart the `withings-mcp` systemd service.

### One-time server setup

Install Bun on the server so `/usr/local/bin/bun` exists. Then install the systemd unit and create the service directories:

```sh
scripts/install-service root@<server-ip>
```

Populate the server environment file:

```sh
scp scripts/withings-mcp.env.example root@<server-ip>:/var/lib/withings-mcp/env
ssh root@<server-ip> '$EDITOR /var/lib/withings-mcp/env'
ssh root@<server-ip> 'chgrp withings-mcp /var/lib/withings-mcp/env && chmod 0640 /var/lib/withings-mcp/env'
```

Use `deploy/caddy/withings-mcp.caddy.example` as a starting point for HTTPS reverse proxying to `127.0.0.1:3000`.

Your Withings developer app redirect URI should be:

```text
https://your-domain.example/callback
```

MCP clients should connect to:

```text
https://your-domain.example/mcp
```

### Deploy

Set `PUBLIC_BASE_URL` so the upstream static pages and `server.json` are rewritten from `withings-mcp.com` to your own domain before bundling:

```sh
PUBLIC_BASE_URL=https://your-domain.example scripts/deploy root@<server-ip>
```

Optional deployment variables:

- `RELEASE_ID` — override release id
- `KEEP_RELEASES` — number of remote releases to retain, default `10`
- `REMOTE_BASE` — default `/var/lib/withings-mcp`
- `SERVICE_NAME` — default `withings-mcp`
- `SERVICE_USER` — default `withings-mcp`
- `SKIP_TYPECHECK=1` — skip `bun run typecheck`

## Repository layout

```text
flake.nix                         Nix dev shell and upstream source pin
patches/withings-mcp/             Local patch applied to upstream source
scripts/materialize-upstream      Create local vendor/withings-mcp checkout
scripts/deploy                    Build and upload a release to Hetzner
scripts/install-service           One-time systemd bootstrap
deploy/systemd/withings-mcp.service
deploy/caddy/withings-mcp.caddy.example
```

## License

This wrapper repo does not currently declare a license. The upstream `akutishevsky/withings-mcp` project is MIT licensed.
