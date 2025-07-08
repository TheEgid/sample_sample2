# ------------------------ ------------------------Stage 1: Update ------------------------ ------------------------
    FROM node:22.17-bookworm-slim AS prebuilder

    RUN npm install pnpm -g

    RUN apt-get update && apt-get install -y \
    curl \
    openssl \
    libreoffice-writer \
    libreoffice-gtk3 \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

    WORKDIR /app

    # ------------------------ ------------------------Stage 2: Build ------------------------ ------------------------
    FROM node:22.17-bookworm-slim AS builder

    COPY --from=prebuilder ./ ./

    WORKDIR /app

    ENV NODE_ENV production
    ENV NEXT_TELEMETRY_DISABLED 1
    ENV NODE_TLS_REJECT_UNAUTHORIZED 0

    COPY package.json pnpm-lock.yaml ./

    RUN pnpm install --frozen-lockfile --prefer-offline

    COPY ./ ./

    RUN pnpm select-schema

    COPY ./prisma ./prisma

    RUN pnpm prisma generate

    RUN pnpm build

    # ------------------------ ------------------------Stage 3: Application ------------------------ ------------------------
    FROM node:22.17-bookworm-slim AS application

    COPY --from=prebuilder ./ ./
    COPY --from=builder /app /app

    WORKDIR /app

    EXPOSE 3006

    ENV NODE_ENV production
    ENV NEXT_TELEMETRY_DISABLED 1
    ENV NODE_TLS_REJECT_UNAUTHORIZED 0

    CMD ["pnpm", "start"]
