FROM node:26-alpine@sha256:2d984a15c9b54fd0aeb608b8e0d0d83529eb34d2966db27a1fb4f1edc3d298a3
RUN addgroup -S mcp && adduser -S mcp -G mcp
# hadolint ignore=DL3016
RUN npm install -g influxdb-mcp-server@0.2.0 --omit=dev && npm cache clean --force
USER mcp
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD nc -z localhost 3000 || exit 1
CMD ["influxdb-mcp-server", "--http", "3000"]
