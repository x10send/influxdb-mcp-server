# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Security
- Pin all GitHub Actions `uses:` references to full commit SHAs (P0-1)
- Pin `node:20-alpine` base image to manifest list digest for reproducible builds (P1-1)
- Move `packages: write`, `attestations: write`, `id-token: write` permissions to job level — `build` job now only gets `packages: write` (P1-2)
- Add `HEALTHCHECK` to Dockerfile so container health is detectable by Docker and Unraid (P2-2)
- Add `.github/dependabot.yml` for weekly automated updates to GitHub Actions and Docker base image (P2-1)
- Add `.github/SECURITY.md` vulnerability reporting policy (P2-3)
- Add `.github/CODEOWNERS` assigning review ownership to @x10send (P3-2)
- Enable branch protection on `main`: require PR review, dismiss stale reviews, enforce on admins, block force-pushes (P3-1)
- Update Unraid template: note `:latest` risk and recommend pinning; add HTTPS prompt to InfluxDB URL description (P2-4, P3-3)

## [0.2.0-1] - 2026-06-02

### Added
- Initial release packaging `influxdb-mcp-server@0.2.0`
- Dockerfile on `node:20-alpine`, runs as non-root `mcp` user
- Multi-arch build (linux/amd64, linux/arm64)
- GitHub Actions workflow publishing to GHCR on `v*.*.*-*` tags
- SBOM and build provenance attestation
- Unraid Community Apps XML template
