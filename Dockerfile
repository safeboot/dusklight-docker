# Dusklight (butterbarned/babyburt) - Node.js server, no build step.
# Needs Node >= 22.5 (built-in node:sqlite).
FROM node:22-slim

ENV NODE_ENV=production
WORKDIR /app

# Install dependencies first for better layer caching
# (only dependency is discord.js, used by the optional staff bot)
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

COPY . .

# Persistent state:
#   /data      -> accounts DB (game.sqlite), backups, logs   (AJ_DATA_DIR)
#   /app/cache -> game files fetched on demand from the public content server
RUN mkdir -p /data /app/cache \
 && chown -R node:node /data /app/cache
VOLUME ["/data", "/app/cache"]

# Inside a container the server must listen on all interfaces
ENV AJ_BIND=0.0.0.0 \
    AJ_DATA_DIR=/data \
    AJ_HTTP_PORT=8080 \
    AJ_GAME_PORT=9339

EXPOSE 8080 9339

USER node

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.AJ_HTTP_PORT||8080)+'/').then(r=>process.exit(r.status<500?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server.js"]