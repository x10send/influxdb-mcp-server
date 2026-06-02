# Project Spec: influxdb-mcp-server

## Goal

Create a GitHub repository that packages the `influxdb-mcp-server` npm package
into a Docker image and publishes it to GitHub Container Registry (GHCR) via
GitHub Actions. The resulting image should be deployable on Unraid through the
normal Docker UI (Add Container) or Community Apps.

---

## Repository Name

`influxdb-mcp-server` (under the `x10send` GitHub org/account)

---

## Target Image

```
ghcr.io/x10send/influxdb-mcp-server:latest
ghcr.io/x10send/influxdb-mcp-server:1.0.0
```

---

## Upstream Package

- **npm package:** `influxdb-mcp-server` by idoru (`github.com/idoru/influxdb-mcp-server`)
- **InfluxDB version:** v2 OSS API (targeting v2.9.x)
- **Transport:** Streamable HTTP (`--http` flag), port 3000

---

## Repository Structure

```
influxdb-mcp-server/
├── .github/
│   └── workflows/
│       └── release.yml          # Build and push to GHCR on tag
├── Dockerfile
├── .dockerignore
├── README.md
├── CHANGELOG.md
└── unraid/
    └── influxdb-mcp-server.xml  # Unraid Community Apps template
```

---

## Dockerfile Requirements

- Base image: `node:20-alpine`
- Install `influxdb-mcp-server` globally from npm at build time (not runtime)
- Run as a non-root user
- Expose port `3000`
- Default CMD: `influxdb-mcp-server --http 3000`
- No secrets baked in — all config via environment variables
- Keep image small; use `--omit=dev` and clean npm cache

```dockerfile
# Example structure — Claude Code should produce the final version
FROM node:20-alpine
RUN addgroup -S mcp && adduser -S mcp -G mcp
RUN npm install -g influxdb-mcp-server --omit=dev && npm cache clean --force
USER mcp
EXPOSE 3000
CMD ["influxdb-mcp-server", "--http", "3000"]
```

---

## Environment Variables

The container must support these env vars (passed through to influxdb-mcp-server):

| Variable | Required | Description |
|---|---|---|
| `INFLUXDB_TOKEN` | Yes | InfluxDB all-access or scoped token |
| `INFLUXDB_URL` | Yes | InfluxDB base URL (e.g. `http://192.168.1.x:8086`) |
| `INFLUXDB_ORG` | Yes | InfluxDB organization name |

---

## GitHub Actions: release.yml

### Trigger
- On pushed version tags: `v*.*.*`

### Steps
1. Checkout repo
2. Set up QEMU (for multi-arch)
3. Set up Docker Buildx
4. Log in to GHCR using `GITHUB_TOKEN`
5. Extract metadata (tags + labels) using `docker/metadata-action`
6. Build and push multi-arch image (`linux/amd64`, `linux/arm64`)
7. Generate SBOM and build provenance attestation (match pattern from `mcp-edge-gateway`)

### Tags to publish
- `ghcr.io/x10send/influxdb-mcp-server:latest`
- `ghcr.io/x10send/influxdb-mcp-server:1` (major)
- `ghcr.io/x10send/influxdb-mcp-server:1.0` (major.minor)
- `ghcr.io/x10send/influxdb-mcp-server:1.0.0` (full semver)

### Permissions required in workflow
```yaml
permissions:
  contents: read
  packages: write
  attestations: write
  id-token: write
```

---

## Unraid Template: unraid/influxdb-mcp-server.xml

Create a Community Apps-compatible XML template so the container can be added
via the Unraid Docker UI without manually filling in fields.

Key fields:
- **Name:** `influxdb-mcp-server`
- **Repository:** `ghcr.io/x10send/influxdb-mcp-server:latest`
- **WebUI:** (none — this is a backend service)
- **Network:** `bridge`
- **Port mapping:** container `3000` → host `3100` (configurable)
- **Environment variables:** `INFLUXDB_TOKEN`, `INFLUXDB_URL`, `INFLUXDB_ORG`
  — all exposed as editable fields with descriptions

---

## README Requirements

Include:
- What this is and why it exists (MCP bridge for InfluxDB v2 OSS)
- Environment variable reference table
- Quick start (Docker run one-liner)
- Unraid deployment instructions (UI and compose)
- How to wire it into `mcp-edge-gateway` via `gateway.yaml`
- Link to upstream `idoru/influxdb-mcp-server`
- Note on the `write` tool denylist in `mcp-edge-gateway` and how to allow it

---

## gateway.yaml Integration Note

Once deployed, add this route to the `mcp-edge-gateway` config:

```yaml
routes:
  - path: /unraid
    upstream: http://unraid-mcp-agent:8043
  - path: /influxdb
    upstream: http://<unraid-host-ip>:3100
```

---

## Quality Bar

- Dockerfile lints clean (`hadolint`)
- Image runs as non-root
- Multi-arch build (amd64 + arm64)
- SBOM + provenance attestation on release (consistent with `mcp-edge-gateway`)
- README is complete enough that someone unfamiliar with MCP can follow it

---

## Out of Scope

- InfluxDB v3 support (use `influxdata/influxdb3-mcp-server` for that)
- Authentication/OAuth (handled by `mcp-edge-gateway`)
- Bundling with the edge gateway repo
