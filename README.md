# influxdb-mcp-server

Docker image that packages [`influxdb-mcp-server`](https://github.com/idoru/influxdb-mcp-server) as a self-contained container for easy deployment on Unraid or any Docker host. Exposes an [MCP](https://modelcontextprotocol.io) interface for InfluxDB v2 OSS over Streamable HTTP so AI tools (Claude, etc.) can query your InfluxDB instance.

Authentication and routing are handled by a separate [`mcp-edge-gateway`](https://github.com/x10send/mcp-edge-gateway) — this container is just the InfluxDB bridge.

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `INFLUXDB_TOKEN` | Yes | InfluxDB all-access or scoped API token |
| `INFLUXDB_URL` | Yes | Base URL of your InfluxDB instance (e.g. `http://192.168.1.x:8086`) |
| `INFLUXDB_ORG` | Yes | InfluxDB organization name |

## Quick Start

```bash
docker run -d \
  --name influxdb-mcp-server \
  -e INFLUXDB_TOKEN=your-token \
  -e INFLUXDB_URL=http://192.168.1.x:8086 \
  -e INFLUXDB_ORG=your-org \
  -p 3002:3000 \
  ghcr.io/x10send/influxdb-mcp-server:latest
```

The MCP server will be available at `http://localhost:3002`.

## Unraid Deployment

### Via Docker UI (Add Container)

1. In Unraid, go to **Docker → Add Container**
2. Set **Name** to `influxdb-mcp-server`
3. Set **Repository** to `ghcr.io/x10send/influxdb-mcp-server:latest`
4. Click **Add another Path, Port, Variable, Label or Device** and add the following port and variables:

**Port:**

| Field | Value |
|---|---|
| Config Type | Port |
| Name | MCP HTTP Port |
| Container Port | `3000` |
| Host Port | `3002` (or any open port on your server) |
| Protocol | TCP |

**Variable 1:**

| Field | Value |
|---|---|
| Config Type | Variable |
| Name | `INFLUXDB_TOKEN` |
| Key | `INFLUXDB_TOKEN` |
| Value | Your InfluxDB API token (find it under **Load Data → API Tokens** in the InfluxDB UI) |

**Variable 2:**

| Field | Value |
|---|---|
| Config Type | Variable |
| Name | `INFLUXDB_URL` |
| Key | `INFLUXDB_URL` |
| Value | `http://<your-unraid-ip>:8086` |

**Variable 3:**

| Field | Value |
|---|---|
| Config Type | Variable |
| Name | `INFLUXDB_ORG` |
| Key | `INFLUXDB_ORG` |
| Value | Your InfluxDB organization name (shown in the top-left dropdown of the InfluxDB UI) |

5. Click **Apply**

The MCP endpoint will be available at `http://<your-unraid-ip>:<host-port>/mcp`.

### Via Community Apps

Search for **influxdb-mcp-server** in the Community Apps store (once the template is published).

### Via Docker Compose

```yaml
services:
  influxdb-mcp-server:
    image: ghcr.io/x10send/influxdb-mcp-server:latest
    restart: unless-stopped
    ports:
      - "3002:3000"
    environment:
      INFLUXDB_TOKEN: ${INFLUXDB_TOKEN}
      INFLUXDB_URL: ${INFLUXDB_URL}
      INFLUXDB_ORG: ${INFLUXDB_ORG}
```

Store secrets in a `.env` file (never commit it):

```
INFLUXDB_TOKEN=your-token
INFLUXDB_URL=http://192.168.1.x:8086
INFLUXDB_ORG=your-org
```

## Wiring into mcp-edge-gateway

Add an `/influxdb` route to your `gateway.yaml` (the gateway appends `/mcp` to the upstream automatically):

```yaml
routes:
  - path: /influxdb
    upstream: http://<unraid-host-ip>:3002
```

### Tool Access

This server exposes four tools: `query-data`, `write-data`, `create-bucket`, and `create-org`.

Use a per-route `allowlist` to explicitly control which tools are available. Read-only:

```yaml
routes:
  - path: /influxdb
    upstream: http://<unraid-host-ip>:3002
    tools:
      allowlist:
        - query-data
```

To also allow writing data (e.g. for Claude to log or annotate measurements):

```yaml
routes:
  - path: /influxdb
    upstream: http://<unraid-host-ip>:3002
    tools:
      allowlist:
        - query-data
        - write-data
```

## Image Details

- Base image: `node:20-alpine`
- Runs as non-root user (`mcp`)
- Multi-arch: `linux/amd64`, `linux/arm64`
- SBOM and provenance attestations on every release

## Upstream

This image is a thin Docker wrapper around the npm package [`influxdb-mcp-server`](https://github.com/idoru/influxdb-mcp-server) by idoru, targeting InfluxDB v2 OSS API (v2.9.x).
