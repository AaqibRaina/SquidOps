FROM node:18-alpine as builder

WORKDIR /squid
RUN apk add python3 make g++

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Build the squid
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /squid
RUN apk add python3 make g++

# Copy built artifacts and install production dependencies
COPY --from=builder /squid/package.json /squid/package-lock.json ./
COPY --from=builder /squid/lib ./lib
COPY --from=builder /squid/schema.graphql ./schema.graphql
COPY --from=builder /squid/db ./db
COPY --from=builder /squid/commands.json ./commands.json
COPY --from=builder /squid/squid.yaml ./squid.yaml
RUN npm ci --production

# Environment variables
ENV NODE_ENV=production
ENV PROCESSOR_PROMETHEUS_PORT=3000
ENV GQL_PORT=4350

# Expose ports for the processor metrics and GraphQL server
EXPOSE 3000
EXPOSE 4350

# Run processor and GraphQL server in parallel
CMD ["sh", "-c", "npx sqd process & npx sqd serve"]