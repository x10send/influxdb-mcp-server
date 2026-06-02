# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repo packages the [`influxdb-mcp-server`](https://github.com/idoru/influxdb-mcp-server) npm package into a Docker image and publishes it to GitHub Container Registry (`ghcr.io/x10send/influxdb-mcp-server`). It is a thin wrapper — no application source code, just a Dockerfile, GitHub Actions workflow, and Unraid Community Apps XML template. The upstream npm package targets InfluxDB v2 OSS API (v2.9.x) and runs an MCP server over Streamable HTTP on port 3000.

## Repository Structure to Build

```
influxdb-mcp-server/
├── .github/workflows/release.yml   # Build and push to GHCR on v*.*.* tags
├── Dockerfile
├── .dockerignore
├── README.md
├── CHANGELOG.md
└── unraid/influxdb-mcp-server.xml  # Community Apps template
```

## Build & Lint Commands

```bash
# Build the image locally
docker build -t influxdb-mcp-server .

# Run locally (requires env vars)
docker run --rm \
  -e INFLUXDB_TOKEN=<token> \
  -e INFLUXDB_URL=http://192.168.1.x:8086 \
  -e INFLUXDB_ORG=<org> \
  -p 3000:3000 \
  influxdb-mcp-server

# Lint the Dockerfile
hadolint Dockerfile
```

## Dockerfile Requirements

- Base: `node:20-alpine`
- Install `influxdb-mcp-server` globally at build time: `npm install -g influxdb-mcp-server --omit=dev && npm cache clean --force`
- Run as non-root user (`mcp` group/user created with `addgroup`/`adduser`)
- Expose port `3000`
- CMD: `["influxdb-mcp-server", "--http", "3000"]`

## GitHub Actions: release.yml

Triggers on `v*.*.*` tags. Steps: checkout → QEMU → Buildx → GHCR login (via `GITHUB_TOKEN`) → metadata-action for tags/labels → multi-arch build+push (`linux/amd64`, `linux/arm64`) → SBOM + provenance attestation.

Required permissions:
```yaml
permissions:
  contents: read
  packages: write
  attestations: write
  id-token: write
```

Tags published: `latest`, major (`1`), major.minor (`1.0`), full semver (`1.0.0`).

## Environment Variables

Passed through to the npm package at runtime — never baked into the image:

| Variable | Required | Description |
|---|---|---|
| `INFLUXDB_TOKEN` | Yes | InfluxDB all-access or scoped token |
| `INFLUXDB_URL` | Yes | InfluxDB base URL (e.g. `http://192.168.1.x:8086`) |
| `INFLUXDB_ORG` | Yes | InfluxDB organization name |

## Unraid Template (unraid/influxdb-mcp-server.xml)

Community Apps-compatible XML. Key fields:
- Repository: `ghcr.io/x10send/influxdb-mcp-server:latest`
- Network: `bridge`
- Port: container `3000` → host `3002` (configurable)
- All three env vars exposed as editable fields with descriptions
- No WebUI entry (backend service only)

## Quality Bar

- `hadolint` must pass clean
- Image runs as non-root
- Multi-arch (amd64 + arm64)
- SBOM + provenance attestation on release (consistent with `mcp-edge-gateway` sibling project)

## Out of Scope

- InfluxDB v3 support
- Authentication/OAuth (handled upstream by `mcp-edge-gateway`)
- Bundling with the edge gateway repo
