FROM node:20-alpine
RUN addgroup -S mcp && adduser -S mcp -G mcp
# hadolint ignore=DL3016
RUN npm install -g influxdb-mcp-server@0.2.0 --omit=dev && npm cache clean --force
USER mcp
EXPOSE 3000
CMD ["influxdb-mcp-server", "--http", "3000"]
