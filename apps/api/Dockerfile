# syntax=docker/dockerfile:1

# ---- Build stage: compile TypeScript to dist/ ----
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY tsconfig.json ./
COPY @types ./@types
COPY src ./src
COPY server.ts ./
RUN npm run build

# ---- Dependencies stage: production node_modules only ----
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# ---- Runtime stage: distroless, non-root ----
FROM gcr.io/distroless/nodejs20-debian12 AS runtime
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080

# Only production deps and compiled output reach the final image.
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package.json ./

# Distroless ships a non-root 'nonroot' user (uid 65532).
USER nonroot
EXPOSE 8080

# The distroless nodejs image's ENTRYPOINT is already `node`.
CMD ["dist/server.js"]
