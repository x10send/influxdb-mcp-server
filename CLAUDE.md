# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repo packages the [`influxdb-mcp-server`](https://github.com/idoru/influxdb-mcp-server) npm package into a Docker image and publishes it to GitHub Container Registry (`ghcr.io/x10send/influxdb-mcp-server`). It is a thin wrapper — no application source code, just a Dockerfile, GitHub Actions workflow, and Unraid Community Apps XML template. The upstream npm package targets InfluxDB v2 OSS API (v2.9.x) and runs an MCP server over Streamable HTTP on port 3000. The MCP endpoint is `/mcp`.

## Repository Structure

```
influxdb-mcp-server/
├── .github/workflows/release.yml   # Build and push to GHCR on v*.*.*-* tags
├── Dockerfile
├── .dockerignore
├── README.md
├── CHANGELOG.md
└── unraid/influxdb-mcp-server.xml  # Community Apps template
```

## Versioning Convention

Tags follow `vX.Y.Z-N` where `X.Y.Z` is the upstream `influxdb-mcp-server` npm version and `N` is the packaging iteration (starting at 1). Example: `v0.2.0-1` means npm `0.2.0`, first packaging release. Bump `N` for Dockerfile or workflow fixes without an upstream npm change. Published Docker tags: `X.Y.Z-N` (full) and `latest`.

## Upgrading the Upstream npm Package

1. Update the pinned version in `Dockerfile`: `npm install -g influxdb-mcp-server@X.Y.Z`
2. Update `CHANGELOG.md`
3. Commit, then tag `vX.Y.Z-1` and push the tag — the workflow builds and publishes automatically

The npm version is pinned (not `latest`) to prevent supply chain attacks. Never remove the pin.

## Build & Lint Commands

```bash
# Build the image locally
docker build -t influxdb-mcp-server .

# Run locally (requires env vars)
docker run --rm \
  -e INFLUXDB_TOKEN=<token> \
  -e INFLUXDB_URL=http://192.168.1.x:8086 \
  -e INFLUXDB_ORG=<org> \
  -p 3002:3000 \
  influxdb-mcp-server

# Lint the Dockerfile
hadolint Dockerfile
```

## Dockerfile

- Base: `node:20-alpine`
- npm package pinned to a specific version at build time (e.g. `influxdb-mcp-server@0.2.0`)
- Non-root user (`mcp` group/user created with `addgroup`/`adduser`)
- Expose port `3000`
- CMD: `["influxdb-mcp-server", "--http", "3000"]`

## GitHub Actions: release.yml

Triggers on `v*.*.*-*` tags. Uses a matrix of native runners (`ubuntu-latest` for amd64, `ubuntu-24.04-arm` for arm64) — QEMU is not used because `npm install` fails under QEMU arm64 emulation (SIGILL). Each arch builds by digest, then a merge job creates the manifest list. Provenance attestation is generated from the merged digest.

Required permissions: `contents: read`, `packages: write`, `attestations: write`, `id-token: write`.

Published Docker tags: `X.Y.Z-N` (full version) and `latest`.

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
- SBOM + provenance attestation on release

## Out of Scope

- InfluxDB v3 support
- Authentication/OAuth (handled upstream by `mcp-edge-gateway`)
- Bundling with the edge gateway repo
