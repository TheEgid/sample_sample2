FROM node:23.10.0-bookworm-slim

RUN apt-get update && apt-get install -y curl build-essential python3

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# 1. Copy minimal files first
COPY package.json pnpm-lock.yaml ./

# 🔥 FIX: Copy required files before install (used by postinstall)
COPY scripts ./scripts
COPY prisma ./prisma

# 2. Now safe to install with postinstall script
RUN pnpm install --frozen-lockfile

# 3. Copy the rest of the app
COPY ./ ./

# 4. Optional: Re-run schema script explicitly (if needed)
RUN npx ts-node --project tsconfig.json ./scripts/select-schema.ts
RUN pnpm prisma generate
RUN pnpm build

EXPOSE 3007
