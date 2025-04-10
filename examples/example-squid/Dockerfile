
FROM node:18-alpine as builder

# Add labels for better management
LABEL maintainer="Kumar Saurabh < <itsksaurabh@gmail.com>"
LABEL version="1.0"

WORKDIR /squid

# Install build dependencies
RUN apk add python3 make g++

# Copy package files first to leverage Docker cache
COPY package.json package-lock.json ./
RUN npm ci

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production image
FROM node:18-alpine

WORKDIR /squid

# Install only production dependencies
RUN apk add --no-cache python3 make g++ netcat-openbsd && \
    ln -sf python3 /usr/bin/python
ENV PYTHON=/usr/bin/python3
COPY --from=builder /squid/package.json /squid/package-lock.json ./
RUN npm ci --production

# Copy built application
COPY --from=builder /squid/lib ./lib
COPY --from=builder /squid/abi ./abi
COPY --from=builder /squid/db ./db
COPY --from=builder /squid/schema.graphql ./schema.graphql
COPY --from=builder /squid/commands.json ./commands.json

# Copy and make the startup script executable
COPY start.sh ./
RUN chmod +x start.sh

# Install global dependencies
RUN npm install -g @subsquid/cli typescript

# Set environment variables
ENV NODE_ENV=production
ENV PROCESSOR_PROMETHEUS_PORT=3000
ENV GQL_PORT=4350

# Expose ports
EXPOSE 3000
EXPOSE 4350

# Start the application using the startup script
CMD ["./start.sh"]