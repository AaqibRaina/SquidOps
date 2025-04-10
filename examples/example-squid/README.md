# Example Squid Project

This example demonstrates a Subsquid indexer implementation that indexes USDC token transfers on Ethereum mainnet, featuring Redis caching and PostgreSQL database integration.

## Prerequisites

- Node.js v16.x or later
- Docker and Docker Compose
- [Squid CLI](https://docs.subsquid.io/squid-cli/)

## Project Structure

- `src/` - Source code for the indexer
- `abi/` - Smart contract ABIs
- `db/` - Database migrations
- `schema.graphql` - GraphQL schema definition
- `docker-compose.yml` - Docker services configuration
- `.env.example` - Environment variables template

## Configuration

1. Copy the environment template:
   ```bash
   cp .env.example .env
   ```

2. Configure the following environment variables in `.env`:

   ```env
   # Database Configuration
   DB_NAME=squid        # PostgreSQL database name
   DB_PORT=23798       # Database port (exposed)
   DB_HOST=localhost   # Database host
   DB_USER=squid       # Database user
   DB_PASS=postgres    # Database password

   # Service Ports
   PROCESSOR_PROMETHEUS_PORT=3000  # Metrics endpoint
   GQL_PORT=4350                   # GraphQL API port

   # Redis Cache Configuration
   REDIS_PORT=6379                 # Redis port (exposed)
   REDIS_PASSWORD=redis            # Redis password
   REDIS_URL=redis://:redis@redis:6379  # Redis connection URL
   ```

## Services

The project includes three main services:

1. **PostgreSQL Database**
   - Stores indexed data
   - Exposed on port specified in `DB_PORT`
   - Includes health checks

2. **Redis Cache**
   - Provides caching layer for improved query performance
   - Persistent storage with AOF enabled
   - Exposed on port specified in `REDIS_PORT`
   - Includes health checks

3. **Squid Indexer**
   - Runs both the processor and GraphQL server
   - Processor available on port 3000 (metrics)
   - GraphQL API available on port 4350
   - Automatically connects to database and cache

## Running the Project

1. Start all services:
   ```bash
   docker-compose up --build
   ```

2. The following endpoints will be available:
   - GraphQL API: `http://localhost:4350/graphql`
   - Metrics: `http://localhost:3000/metrics`

## Sample Queries

Once the GraphQL API is running, you can execute queries at `http://localhost:4350/graphql`. Here are some example queries:

1. Get recent USDC transfers with details:
   ```graphql
   query GetRecentTransfers {
     transfers(orderBy: timestamp_DESC, limit: 5) {
       id
       blockNumber
       timestamp
       txHash
       amount # Amount in USDC (6 decimals)
       from {
         id
       }
       to {
         id
       }
     }
   }
   ```

2. Get USDC transfer history for a specific account:
   ```graphql
   # Query
   query GetAccountDetails($accountId: String!) {
     accounts(where: {id_eq: $accountId}) {
       id
       transfersFrom {
         timestamp
         amount # Amount in USDC (6 decimals)
         to { id }
         txHash
       }
       transfersTo {
         timestamp
         amount # Amount in USDC (6 decimals)
         from { id }
         txHash
       }
     }
   }

   # Variables (in GraphQL Playground Variables tab)
   {
     "accountId": "0x55fe002aeff02f77364de339a1292923a15844b8" # Example USDC holder address
   }
   ```

Note: The indexer tracks the USDC token contract (0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48) on Ethereum mainnet starting from block 6,082,465. All amounts are in USDC with 6 decimal places (e.g., 1000000 = 1 USDC).

## Development

- Modify `schema.graphql` to update the data model
- Update processor logic in `src/`
- Add new contract ABIs in `abi/`
- Run database migrations with `npx squid-typeorm-migration apply`

## Monitoring

- Database and Redis health checks are configured
- Processor metrics available via Prometheus endpoint
- GraphQL subscriptions enabled for real-time updates

## Support

For more information about Subsquid development:
- [Subsquid Documentation](https://docs.subsquid.io/)
- [Discord Community](https://discord.com/invite/subsquid)
