# Q3 2026 Security Updates

Security review of the `influxdb-mcp-server` packaging repo conducted 2026-08-31.
Items are phased by priority: **P0** (critical, fix immediately) → **P3** (low, improve when convenient).

---

## P0 — Critical

### ~~P0-1: GitHub Actions not pinned to commit SHAs~~ ✓ DONE

**File:** `.github/workflows/release.yml`

All eight `uses:` references use mutable version tags (`@v3`, `@v4`, `@v5`, `@v6`, `@v2`). If any upstream action is compromised or its tag is force-pushed, malicious code runs inside the workflow with `packages: write` and `id-token: write` permissions — enough to publish a backdoored image or forge attestations.

**Affected lines:**
| Action | Current ref | Fix |
|---|---|---|
| `actions/checkout` | `@v4` | pin to SHA |
| `docker/setup-buildx-action` | `@v3` | pin to SHA |
| `docker/login-action` | `@v3` | pin to SHA |
| `docker/metadata-action` | `@v5` | pin to SHA |
| `docker/build-push-action` | `@v6` | pin to SHA |
| `actions/upload-artifact` | `@v4` | pin to SHA |
| `actions/download-artifact` | `@v4` | pin to SHA |
| `actions/attest-build-provenance` | `@v2` | pin to SHA |

**Fix:** Replace every `uses: owner/action@vN` with `uses: owner/action@<full-sha>  # vN`. Obtain SHAs from each action repo's release page or via `gh release view`. Add Dependabot for `github-actions` ecosystem so pinned SHAs stay current automatically.

---

## P1 — High

### ~~P1-1: Base image not pinned to a digest~~ ✓ DONE

**File:** `Dockerfile`, line 1

```dockerfile
FROM node:20-alpine
```

`node:20-alpine` resolves to whatever the latest patch build is at `docker pull` time. This means two builds of the same tag can produce different images, and a compromised Docker Hub push of `node:20-alpine` would silently affect future builds.

**Fix:**
```dockerfile
FROM node:20-alpine@sha256:<digest>  # 20.x.y-alpine3.xx
```
Pin the digest and update it deliberately on each Node.js patch release (automate with Dependabot Docker ecosystem or Renovate).

### ~~P1-2: Workflow permissions granted at workflow level instead of job level~~ ✓ DONE

**File:** `.github/workflows/release.yml`, lines 11–15

```yaml
permissions:
  contents: read
  packages: write
  attestations: write
  id-token: write
```

`packages: write`, `attestations: write`, and `id-token: write` are workflow-scoped, so every job (including `build` on untrusted runners) receives them. Only the `merge` job needs write access.

**Fix:** Remove the top-level `permissions` block. Add minimal per-job permissions:

```yaml
jobs:
  build:
    permissions:
      contents: read
      packages: write          # needed to push by digest
    ...

  merge:
    permissions:
      contents: read
      packages: write          # needed to create manifest + push
      attestations: write
      id-token: write
```

---

## P2 — Medium

### ~~P2-1: No automated dependency update policy (Dependabot/Renovate)~~ ✓ DONE

There is no `.github/dependabot.yml` or Renovate config. The npm package version, base image digest, and all action SHAs will drift silently.

**Fix:** Add `.github/dependabot.yml` covering at minimum:
- `package-ecosystem: github-actions` — updates action SHAs weekly
- `package-ecosystem: docker` — updates base image digest

Example:
```yaml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
  - package-ecosystem: docker
    directory: /
    schedule:
      interval: weekly
```

### ~~P2-2: No Dockerfile HEALTHCHECK~~ ✓ DONE

**File:** `Dockerfile`

The container has no `HEALTHCHECK` instruction, so Docker and Unraid cannot distinguish a crashed server from a healthy one. Unraid restart policies rely on container health state.

**Fix:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/mcp || exit 1
```
Verify the correct liveness path against the upstream `influxdb-mcp-server` package before merging.

### ~~P2-3: No security policy (SECURITY.md)~~ ✓ DONE

There is no `SECURITY.md` defining how to report vulnerabilities. This also prevents GitHub from surfacing the "Report a vulnerability" button on the repo.

**Fix:** Add `.github/SECURITY.md` with a contact method (e.g., GitHub private vulnerability reporting or email) and a supported-versions table.

### ~~P2-4: Unraid template uses `:latest` image tag~~ ✓ DONE

**File:** `unraid/influxdb-mcp-server.xml`, line 4

```xml
<Repository>ghcr.io/x10send/influxdb-mcp-server:latest</Repository>
```

Users who enable "auto-update" in Unraid's Community Apps will pull any future `latest` push without review, including breaking changes or a compromised image.

**Recommendation:** Document in README and template description that users should prefer pinning to a specific version tag (e.g., `0.2.0-1`) and only update after reviewing the CHANGELOG. Consider adding a `<Config>` field for the image tag defaulting to the current pinned version.

---

## P3 — Low

### ~~P3-1: No branch protection rules documented~~ ✓ DONE

There is no record of branch protection on `main` (e.g., requiring PR review, status checks, or signed commits). Without branch protection, any collaborator with write access could push directly to `main` and trigger a release by pushing a matching tag.

**Fix:** Enable branch protection on `main` via GitHub repo Settings → Branches:
- Require pull request review before merging
- Require status checks to pass (add a `hadolint` lint job)
- Restrict who can push matching tags

### ~~P3-2: No CODEOWNERS file~~ ✓ DONE

No `.github/CODEOWNERS` is present. This means GitHub won't auto-assign reviewers on PRs or enforce required reviews from specific owners.

**Fix:** Add `.github/CODEOWNERS`:
```
* @x10send
```

### ~~P3-3: Plain HTTP default for InfluxDB URL~~ ✓ DONE

**File:** `unraid/influxdb-mcp-server.xml`, line 25

The default `INFLUXDB_URL` is `http://192.168.1.x:8086` (plain HTTP). If a user's InfluxDB instance has TLS available, credentials and query results traverse the local network unencrypted.

**Note:** For a typical Unraid LAN deployment this is acceptable, but users with TLS-enabled InfluxDB should be prompted to use `https://`. Update the field description to mention HTTPS.

---

## Summary Table

| ID | Priority | File | Issue |
|---|---|---|---|
| ~~P0-1~~ | ~~P0~~ | `release.yml` | ~~Action refs not pinned to SHA~~ ✓ |
| ~~P1-1~~ | ~~P1~~ | `Dockerfile` | ~~Base image not pinned to digest~~ ✓ |
| ~~P1-2~~ | ~~P1~~ | `release.yml` | ~~Workflow-level write permissions~~ ✓ |
| ~~P2-1~~ | ~~P2~~ | `.github/dependabot.yml` | ~~No Dependabot/Renovate config~~ ✓ |
| ~~P2-2~~ | ~~P2~~ | `Dockerfile` | ~~No HEALTHCHECK~~ ✓ |
| ~~P2-3~~ | ~~P2~~ | `.github/SECURITY.md` | ~~No SECURITY.md~~ ✓ |
| ~~P2-4~~ | ~~P2~~ | `influxdb-mcp-server.xml` | ~~`:latest` tag in Unraid template~~ ✓ |
| ~~P3-1~~ | ~~P3~~ | (repo settings) | ~~Branch protection not documented~~ ✓ |
| ~~P3-2~~ | ~~P3~~ | `.github/CODEOWNERS` | ~~No CODEOWNERS~~ ✓ |
| ~~P3-3~~ | ~~P3~~ | `influxdb-mcp-server.xml` | ~~HTTP default URL, no TLS prompt~~ ✓ |
