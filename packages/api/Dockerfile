FROM node:20-alpine AS base
RUN corepack enable && corepack prepare pnpm@9 --activate
RUN apk add --no-cache openssl wget

WORKDIR /app
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY packages/api/package.json ./packages/api/package.json
COPY packages/db/package.json ./packages/db/package.json
COPY packages/blockchain/package.json ./packages/blockchain/package.json
COPY apps/web/package.json ./apps/web/package.json
RUN pnpm install --frozen-lockfile
COPY . .
RUN pnpm --filter=@jagafinance/db generate

EXPOSE 3001
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider "http://localhost:$PORT/api/v1/health" || exit 1
CMD ["pnpm", "--filter=@jagafinance/api", "exec", "tsx", "src/index.ts"]
