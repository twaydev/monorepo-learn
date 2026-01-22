# Railway Deployment Guide

This guide covers deploying the SaaS Product monorepo to Railway with automated CI/CD via GitHub Actions.

## Quick Start

Run the automated setup script:

```bash
make railway-init
# or
./scripts/railway-init.sh
```

This script will:
1. Check Railway CLI installation
2. Authenticate with Railway
3. Create/link a Railway project
4. Add PostgreSQL database
5. Create all services with environment variables
6. Guide you through GitHub secret setup

## Architecture Overview

```
Railway Project: saaas-product
├── Environments
│   ├── production (main branch)
│   ├── staging (staging branch)
│   └── pr-* (PR preview environments)
│
├── Services (6 total)
│   ├── frontend (Next.js)
│   ├── api-gateway (Go)
│   ├── php-api (Symfony)
│   ├── go-api (Go)
│   ├── rust-api (Rust)
│   └── postgres (Railway PostgreSQL)
│
└── Networking
    └── Private networking between services
    └── Public domain on frontend + api-gateway
```

## Prerequisites

1. [Railway account](https://railway.app)
2. [Railway CLI](https://docs.railway.com/guides/cli) installed
3. GitHub repository with push access
4. Docker images pushed to GHCR (GitHub Container Registry)

### Installing Railway CLI

```bash
# npm
npm install -g @railway/cli

# Homebrew (macOS)
brew install railway

# Shell script
curl -fsSL https://railway.app/install.sh | sh
```

For more details: https://docs.railway.com/guides/cli#installing-the-cli

## Manual Railway Setup

If you prefer manual setup over the automated script:

### 1. Authenticate with Railway

```bash
# Browser login (interactive)
railway login

# Token login (CI/headless)
railway login --browserless
```

For more details: https://docs.railway.com/guides/cli#authenticating-with-the-cli

### 2. Create or Link Project

```bash
# Create new project
railway init --name saaas-product

# Or link to existing project
railway link
```

For more details: https://docs.railway.com/guides/cli#create-a-project

### 3. Add PostgreSQL Database

```bash
railway add --database postgres
```

For more details: https://docs.railway.com/guides/cli#add-database-service

### 4. Create Services

```bash
railway service create frontend
railway service create api-gateway
railway service create php-api
railway service create go-api
railway service create rust-api
```

### 5. Create Staging Environment

```bash
railway environment create staging
```

PR environments are created automatically by the GitHub workflow

## Environment Variables

Configure these in Railway Dashboard for each service:

### All Services
```
RAILWAY_ENVIRONMENT=production|staging|pr-*
```

### Frontend
```
NODE_ENV=production
NEXT_PUBLIC_API_URL=https://${{api-gateway.RAILWAY_PUBLIC_DOMAIN}}
PORT=3000
```

### API Gateway
```
PHP_BACKEND_URL=http://php-api.railway.internal
RUST_BACKEND_URL=http://rust-api.railway.internal
GO_BACKEND_URL=http://go-api.railway.internal
FRONTEND_URL=http://frontend.railway.internal
PORT=8080
```

### PHP API
```
APP_ENV=prod
APP_SECRET=${{secret}}
DATABASE_URL=${{Postgres.DATABASE_URL}}
PORT=80
```

### Go API
```
DATABASE_URL=${{Postgres.DATABASE_URL}}
PORT=80
```

### Rust API
```
DATABASE_URL=${{Postgres.DATABASE_URL}}
RUST_BACKTRACE=0
PORT=80
```

## GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets → Actions):

| Secret | Description |
|--------|-------------|
| `RAILWAY_TOKEN` | Railway API token from [railway.app/account/tokens](https://railway.app/account/tokens) |

## CI/CD Workflows

### deploy-railway.yml

Triggers on:
- Push to `main` → deploys to **production**
- Push to `staging` → deploys to **staging**
- PR opened/updated → creates **pr-{number}** preview environment
- PR closed → deletes preview environment

### build-images.yml

Builds and pushes Docker images to GHCR on push to `main`. Images are tagged with:
- `latest` - for production
- `{git-sha}` - for traceability

## Deployment Flow

```
1. Developer pushes to branch
           ↓
2. GitHub Actions triggers
           ↓
3. Build images (matrix strategy)
   - frontend
   - api-gateway
   - php-api
   - go-api
   - rust-api
           ↓
4. Push to GHCR with tags
           ↓
5. Deploy to Railway
           ↓
6. Run migrations (prod/staging only)
```

## Service Configuration Files

Each service has a `railway.json` file:

| Service | Location |
|---------|----------|
| Root | `railway.json` |
| Frontend | `frontend/railway.json` |
| API Gateway | `go-services/services/api-gateway/railway.json` |
| Go API | `go-services/services/api-service/railway.json` |
| PHP API | `php-services/railway.json` |
| Rust API | `rust-services/railway.json` |

## Verification

### Check Service Status
```bash
railway status
```

### View Logs
```bash
railway logs --service frontend
railway logs --service api-gateway
railway logs --service php-api
railway logs --service go-api
railway logs --service rust-api
```

### Test Health Endpoints
```bash
# Replace with your Railway domain
DOMAIN="your-app.railway.app"

curl https://$DOMAIN/health
curl https://$DOMAIN/services/php-apis/health
curl https://$DOMAIN/services/go-apis/health
curl https://$DOMAIN/services/rust-apis/health
```

## Troubleshooting

### Build Failures

1. Check GitHub Actions logs for build errors
2. Verify Dockerfile paths in `railway.json` files
3. Ensure all dependencies are properly declared

### Deployment Failures

1. Check Railway logs: `railway logs --service <service-name>`
2. Verify environment variables are set correctly
3. Check health endpoint returns 200

### Database Connection Issues

1. Verify `DATABASE_URL` is properly referenced from Postgres service
2. Check if migrations have run successfully
3. Test connection from Railway shell: `railway run --service php-api psql $DATABASE_URL`

### Service Communication Issues

1. Verify internal URLs use `.railway.internal` domain
2. Check if services are in the same Railway project
3. Verify PORT environment variable is set correctly

## Cost Considerations

Railway pricing (estimated):
- 5 services × ~$3-5/service = $15-25/mo
- PostgreSQL: ~$5-10/mo
- **Production only**: ~$20-35/month
- **With staging**: ~$40-70/month

## Security Checklist

- [ ] Railway API token stored as GitHub secret (not in code)
- [ ] Database credentials managed by Railway
- [ ] APP_SECRET for PHP generated and stored in Railway
- [ ] No hardcoded secrets in Dockerfiles
- [ ] Private networking between services
- [ ] HTTPS enforced on public domains

## Useful Commands

```bash
# Open Railway dashboard
railway open

# Connect to service shell
railway shell --service php-api

# Run one-off command
railway run --service php-api php bin/console cache:clear

# View environment variables
railway variables

# Deploy manually
railway up
```
