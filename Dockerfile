FROM node:20-alpine@sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293
RUN addgroup -S mcp && adduser -S mcp -G mcp
# hadolint ignore=DL3016
RUN npm install -g influxdb-mcp-server@0.2.0 --omit=dev && npm cache clean --force
USER mcp
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD nc -z localhost 3000 || exit 1
CMD ["influxdb-mcp-server", "--http", "3000"]
