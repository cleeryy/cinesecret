# syntax=docker/dockerfile:1
FROM node:20-alpine AS base
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

# Dependencies stage
FROM base AS dependencies
RUN apk add --no-cache libc6-compat openssl
COPY package.json pnpm-lock.yaml* ./
RUN corepack enable pnpm && pnpm i --frozen-lockfile --ignore-scripts

# Build stage
FROM base AS build
RUN apk add --no-cache libc6-compat openssl
COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

# Set dummy environment variables for build
ENV AUTH_SECRET="dummy-secret-for-build-only"
ENV DATABASE_URL="postgresql://dummy:dummy@dummy:5432/dummy"
ENV AUTH_GOOGLE_ID="dummy-google-id"
ENV AUTH_GOOGLE_SECRET="dummy-google-secret"
ENV AUTH_TRUST_HOST="true"

# Generate Prisma client and build
RUN corepack enable pnpm && pnpm prisma generate
RUN pnpm build

# Production stage - Version simplifiée
FROM base AS production
ENV NODE_ENV=production
RUN apk add --no-cache libc6-compat openssl

# Create user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy everything needed (y compris node_modules pour Prisma)
COPY --from=build --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=build --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=build --chown=nextjs:nodejs /app/prisma ./prisma
COPY --from=build --chown=nextjs:nodejs /app/node_modules ./node_modules

# Create public directory
RUN mkdir -p ./src/public && chown nextjs:nodejs ./src/public
COPY --from=build --chown=nextjs:nodejs /app/src/public ./src/public 2>/dev/null || true

USER nextjs
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
