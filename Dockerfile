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
# Install OpenSSL for Prisma
RUN apk add --no-cache libc6-compat openssl

COPY --from=dependencies /app/node_modules ./node_modules
COPY . .

# Set dummy environment variables for build
ENV AUTH_SECRET="dummy-secret-for-build-only"
ENV DATABASE_URL="postgresql://dummy:dummy@dummy:5432/dummy"
ENV AUTH_GOOGLE_ID="dummy-google-id"  
ENV AUTH_GOOGLE_SECRET="dummy-google-secret"
ENV AUTH_TRUST_HOST="true"

# Generate Prisma client avec OpenSSL
RUN corepack enable pnpm && pnpm prisma generate

# Build the application
RUN pnpm build

# Production stage  
FROM base AS production
ENV NODE_ENV=production

# Install OpenSSL for Prisma runtime
RUN apk add --no-cache libc6-compat openssl

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Create .next directory with proper permissions
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Copy built application
COPY --from=build --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=build --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy public directory (create if doesn't exist)
RUN mkdir -p ./public
COPY --from=build --chown=nextjs:nodejs /app/public ./public

# Copy Prisma files
COPY --from=build /app/prisma ./prisma/
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma ./node_modules/@prisma

USER nextjs

EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
