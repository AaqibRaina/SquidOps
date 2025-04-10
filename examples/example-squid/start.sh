#!/bin/sh
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}

# Wait for the database to be ready
echo "Waiting for database to be ready..."
while ! nc -z "$DB_HOST" "$DB_PORT"; do
  sleep 1
done

# Run migrations
echo "Running database migrations..."
npx squid-typeorm-migration apply

# Start both the processor and GraphQL server
echo "Starting the processor and GraphQL server..."
node lib/main.js & # Run processor in background

# Check if REDIS_URL is set and use appropriate cache
if [ -n "$REDIS_URL" ]; then
    echo "Using Redis cache with URL: $REDIS_URL"
    npx squid-graphql-server --dumb-cache redis --subscriptions
else
    echo "Using in-memory cache"
    npx squid-graphql-server --dumb-cache in-memory --subscriptions
fi