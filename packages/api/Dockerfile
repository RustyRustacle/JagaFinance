FROM node:20-alpine AS base

# Install pnpm and OpenSSL (required for Prisma on Alpine)
RUN corepack enable && corepack prepare pnpm@9 --activate
RUN apk add --no-cache openssl

FROM base AS deps
WORKDIR /app
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY packages/api/package.json ./packages/api/package.json
COPY packages/db/package.json ./packages/db/package.json
RUN pnpm install --frozen-lockfile

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Re-link binaries (COPY breaks pnpm symlinks)
RUN pnpm install --frozen-lockfile 2>/dev/null || true
RUN pnpm --filter=@jagafinance/db generate && \
    pnpm --filter=@jagafinance/api build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/packages/api/dist ./dist
COPY --from=builder /app/packages/api/package.json ./
COPY --from=builder /app/node_modules ./node_modules

EXPOSE 3001
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/api/v1/health || exit 1
USER nobody
CMD ["node", "dist/index.js"]
