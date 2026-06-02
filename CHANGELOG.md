# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0-1] - 2026-06-02

### Added
- Initial release packaging `influxdb-mcp-server@0.2.0`
- Dockerfile on `node:20-alpine`, runs as non-root `mcp` user
- Multi-arch build (linux/amd64, linux/arm64)
- GitHub Actions workflow publishing to GHCR on `v*.*.*-*` tags
- SBOM and build provenance attestation
- Unraid Community Apps XML template
