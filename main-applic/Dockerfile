FROM node:23.10.0-bookworm-slim

RUN apt-get update && apt-get install -y curl

WORKDIR /app


RUN npm install pnpm -g

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile

COPY ./ ./

EXPOSE 3007

ENV NODE_ENV production

ENV NEXT_TELEMETRY_DISABLED 1

ENV NODE_TLS_REJECT_UNAUTHORIZED 0

RUN pnpm prisma generate

RUN pnpm build

CMD ["pnpm", "start"]
