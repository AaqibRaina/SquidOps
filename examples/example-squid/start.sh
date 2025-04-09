#!/bin/sh

# Wait for the database to be ready
echo "Waiting for database to be ready..."
while ! nc -z db 5432; do
  sleep 1
done

# Run migrations
echo "Running database migrations..."
npx squid-typeorm-migration apply

# Start both the processor and GraphQL server
echo "Starting the processor and GraphQL server..."
node lib/main.js & # Run processor in background
npx squid-graphql-server --dumb-cache in-memory --subscriptions 