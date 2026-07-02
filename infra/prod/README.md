# Production deployment

Runs the prebuilt image (`ghcr.io/sgrumo/quantotelarischi-be:latest`, published by
the `Build Image` workflow) via Docker Compose on a remote machine.

There is no database — the app keeps all state in memory.

## First-time setup on the remote machine

```bash
# 1. Copy this folder to the server, then:
cd infra/prod
cp .env.example .env
# 2. Fill in .env (generate a secret with: openssl rand -base64 64)
$EDITOR .env

# 3. Log in to GHCR (needs a PAT with read:packages if the image is private)
echo "$GHCR_TOKEN" | docker login ghcr.io -u <github-username> --password-stdin

# 4. Start it
docker compose up -d
```

The app is published on host port `:4001` (container listens on `4000`). Put a
reverse proxy (Caddy / nginx / Traefik) in front for TLS and to route
`PHX_HOST` → `127.0.0.1:4001`.

## Updating to a new build

```bash
docker compose pull
docker compose up -d
```

## Operations

```bash
docker compose logs -f app      # tail logs
docker compose ps               # status / health
docker compose down             # stop
```
