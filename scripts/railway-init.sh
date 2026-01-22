#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="saaas-product"
GHCR_REPO="ghcr.io/twaydev/monorepo-learn"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Railway Infrastructure Setup - ${PROJECT_NAME}${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

#==============================================================================
# Step 1: Check Railway CLI
#==============================================================================
echo -e "${BLUE}Step 1: Check Railway CLI${NC}"
echo "----------------------------------------"

if command -v railway &> /dev/null; then
    RAILWAY_VERSION=$(railway --version 2>/dev/null || echo "unknown")
    echo -e "${GREEN}✓${NC} Railway CLI installed: ${RAILWAY_VERSION}"
else
    echo -e "${RED}✗${NC} Railway CLI is not installed."
    echo ""
    echo "Install Railway CLI using one of these methods:"
    echo ""
    echo "  npm:"
    echo -e "    ${YELLOW}npm install -g @railway/cli${NC}"
    echo ""
    echo "  Homebrew (macOS):"
    echo -e "    ${YELLOW}brew install railway${NC}"
    echo ""
    echo "  Shell script:"
    echo -e "    ${YELLOW}curl -fsSL https://railway.app/install.sh | sh${NC}"
    echo ""
    echo -e "For more details: ${BLUE}https://docs.railway.com/guides/cli#installing-the-cli${NC}"
    exit 1
fi
echo ""

#==============================================================================
# Step 2: Login to Railway
#==============================================================================
echo -e "${BLUE}Step 2: Login to Railway${NC}"
echo "----------------------------------------"

if railway whoami &> /dev/null; then
    RAILWAY_USER=$(railway whoami 2>/dev/null)
    echo -e "${GREEN}✓${NC} Already logged in as: ${BLUE}${RAILWAY_USER}${NC}"
else
    echo "You need to authenticate with Railway."
    echo ""
    echo "Options:"
    echo "  1. Browser login (interactive):"
    echo -e "     ${YELLOW}railway login${NC}"
    echo ""
    echo "  2. Token login (CI/headless):"
    echo -e "     ${YELLOW}railway login --browserless${NC}"
    echo ""
    echo -e "For more details: ${BLUE}https://docs.railway.com/guides/cli#authenticating-with-the-cli${NC}"
    echo ""
    read -p "Press Enter to run 'railway login'... "
    railway login

    if railway whoami &> /dev/null; then
        RAILWAY_USER=$(railway whoami 2>/dev/null)
        echo -e "${GREEN}✓${NC} Logged in as: ${BLUE}${RAILWAY_USER}${NC}"
    else
        echo -e "${RED}✗${NC} Login failed. Please try again."
        exit 1
    fi
fi
echo ""

#==============================================================================
# Step 3: Link or Create Project
#==============================================================================
echo -e "${BLUE}Step 3: Link or Create Project${NC}"
echo "----------------------------------------"

if [ -f ".railway/config.json" ]; then
    echo -e "${YELLOW}!${NC} Railway project already linked in this directory."
    railway status 2>/dev/null || true
    echo ""
    read -p "Keep existing link? (Y/n): " KEEP_LINK
    if [[ "$(echo "$KEEP_LINK" | tr '[:upper:]' '[:lower:]')" == "n" ]]; then
        rm -rf .railway
        echo "Removed existing link."
    else
        echo -e "${GREEN}✓${NC} Using existing project link"
    fi
fi

if [ ! -f ".railway/config.json" ]; then
    echo ""
    echo "Options:"
    echo "  1. Create a new project (default)"
    echo "  2. Link to an existing project"
    echo ""
    echo -e "For more details: ${BLUE}https://docs.railway.com/guides/cli#create-a-project${NC}"
    echo ""
    read -p "Create new project? (Y/n): " CREATE_NEW

    if [[ "$(echo "$CREATE_NEW" | tr '[:upper:]' '[:lower:]')" == "n" ]]; then
        echo ""
        echo "Running 'railway link' to connect to existing project..."
        railway link
    else
        echo ""
        echo "Creating new project: ${PROJECT_NAME}"
        railway init --name "${PROJECT_NAME}"
    fi

    echo -e "${GREEN}✓${NC} Project configured"
fi
echo ""

#==============================================================================
# Step 4: Add Database Service
#==============================================================================
echo -e "${BLUE}Step 4: Add Database Service${NC}"
echo "----------------------------------------"

echo "Adding PostgreSQL database to the project..."
echo ""
echo -e "For more details: ${BLUE}https://docs.railway.com/guides/cli#add-database-service${NC}"
echo ""

# Check if postgres already exists
if railway status 2>/dev/null | grep -qi "postgres"; then
    echo -e "${YELLOW}!${NC} PostgreSQL service may already exist."
    read -p "Skip database creation? (Y/n): " SKIP_DB
    if [[ "$(echo "$SKIP_DB" | tr '[:upper:]' '[:lower:]')" != "n" ]]; then
        echo -e "${GREEN}✓${NC} Skipping database creation"
    else
        railway add --database postgres
        echo -e "${GREEN}✓${NC} PostgreSQL database added"
    fi
else
    railway add --database postgres
    echo -e "${GREEN}✓${NC} PostgreSQL database added"
fi
echo ""

#==============================================================================
# Step 5: Create Services and Configure Variables
#==============================================================================
echo -e "${BLUE}Step 5: Create Services and Configure Variables${NC}"
echo "----------------------------------------"

# Generate APP_SECRET for PHP
APP_SECRET=$(openssl rand -hex 32 2>/dev/null || echo "change-me-$(date +%s)")

# Database URL reference for Railway
DB_URL_REF='\${{Postgres.DATABASE_URL}}'

echo ""
echo "Creating services with environment variables..."
echo ""

# Frontend service
echo -n "Creating frontend service... "
if railway add --service "frontend" \
    --image "${GHCR_REPO}/frontend:latest" \
    --variables "NODE_ENV=production" \
    --variables "PORT=3000" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}(may already exist, setting variables)${NC}"
    railway variables --set "NODE_ENV=production" --set "PORT=3000" -s frontend 2>/dev/null || true
fi

# API Gateway service
echo -n "Creating api-gateway service... "
if railway add --service "api-gateway" \
    --image "${GHCR_REPO}/api-gateway:latest" \
    --variables "PHP_BACKEND_URL=http://php-api.railway.internal" \
    --variables "RUST_BACKEND_URL=http://rust-api.railway.internal" \
    --variables "GO_BACKEND_URL=http://go-api.railway.internal" \
    --variables "FRONTEND_URL=http://frontend.railway.internal" \
    --variables "PORT=8080" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}(may already exist, setting variables)${NC}"
    railway variables -s api-gateway \
        --set "PHP_BACKEND_URL=http://php-api.railway.internal" \
        --set "RUST_BACKEND_URL=http://rust-api.railway.internal" \
        --set "GO_BACKEND_URL=http://go-api.railway.internal" \
        --set "FRONTEND_URL=http://frontend.railway.internal" \
        --set "PORT=8080" 2>/dev/null || true
fi

# PHP API service
echo -n "Creating php-api service... "
if railway add --service "php-api" \
    --image "${GHCR_REPO}/php-api:latest" \
    --variables "APP_ENV=prod" \
    --variables "APP_SECRET=${APP_SECRET}" \
    --variables "DATABASE_URL=${DB_URL_REF}" \
    --variables "PORT=80" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}(may already exist, setting variables)${NC}"
    railway variables -s php-api \
        --set "APP_ENV=prod" \
        --set "APP_SECRET=${APP_SECRET}" \
        --set "DATABASE_URL=${DB_URL_REF}" \
        --set "PORT=80" 2>/dev/null || true
fi

# Go API service
echo -n "Creating go-api service... "
if railway add --service "go-api" \
    --image "${GHCR_REPO}/go-api:latest" \
    --variables "DATABASE_URL=${DB_URL_REF}" \
    --variables "PORT=80" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}(may already exist, setting variables)${NC}"
    railway variables -s go-api \
        --set "DATABASE_URL=${DB_URL_REF}" \
        --set "PORT=80" 2>/dev/null || true
fi

# Rust API service
echo -n "Creating rust-api service... "
if railway add --service "rust-api" \
    --image "${GHCR_REPO}/rust-api:latest" \
    --variables "DATABASE_URL=${DB_URL_REF}" \
    --variables "RUST_BACKTRACE=0" \
    --variables "PORT=80" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${YELLOW}(may already exist, setting variables)${NC}"
    railway variables -s rust-api \
        --set "DATABASE_URL=${DB_URL_REF}" \
        --set "RUST_BACKTRACE=0" \
        --set "PORT=80" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}✓${NC} All services created and configured"
echo ""

#==============================================================================
# Step 6: Generate Public Domains
#==============================================================================
echo -e "${BLUE}Step 6: Generate Public Domains${NC}"
echo "----------------------------------------"
echo ""
echo "Generating Railway domains for public-facing services..."
echo ""

# Generate domain for api-gateway
echo -n "Generating domain for api-gateway... "
API_GATEWAY_OUTPUT=$(railway domain -s api-gateway 2>&1)
API_GATEWAY_DOMAIN=$(echo "$API_GATEWAY_OUTPUT" | grep -oE 'https://[a-z0-9-]+\.up\.railway\.app' | sed 's|https://||' | head -1)
if [ -n "$API_GATEWAY_DOMAIN" ]; then
    echo -e "${GREEN}✓${NC} ${BLUE}https://${API_GATEWAY_DOMAIN}${NC}"
else
    echo -e "${YELLOW}(may already exist or manual setup needed)${NC}"
    # Try to get existing domain from variables
    API_GATEWAY_DOMAIN=$(railway variables -s api-gateway 2>/dev/null | grep RAILWAY_PUBLIC_DOMAIN | awk '{print $3}')
fi

# Generate domain for frontend
echo -n "Generating domain for frontend... "
FRONTEND_OUTPUT=$(railway domain -s frontend 2>&1)
FRONTEND_DOMAIN=$(echo "$FRONTEND_OUTPUT" | grep -oE 'https://[a-z0-9-]+\.up\.railway\.app' | sed 's|https://||' | head -1)
if [ -n "$FRONTEND_DOMAIN" ]; then
    echo -e "${GREEN}✓${NC} ${BLUE}https://${FRONTEND_DOMAIN}${NC}"
else
    echo -e "${YELLOW}(may already exist or manual setup needed)${NC}"
    # Try to get existing domain from variables
    FRONTEND_DOMAIN=$(railway variables -s frontend 2>/dev/null | grep RAILWAY_PUBLIC_DOMAIN | awk '{print $3}')
fi

echo ""

# Update frontend with api-gateway URL if we got it
if [ -n "$API_GATEWAY_DOMAIN" ]; then
    echo -n "Setting NEXT_PUBLIC_API_URL on frontend... "
    if railway variables -s frontend --set "NEXT_PUBLIC_API_URL=https://${API_GATEWAY_DOMAIN}" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${YELLOW}(may need manual config)${NC}"
    fi
    echo ""
fi

echo -e "${GREEN}✓${NC} Public domains configured"
echo ""

#==============================================================================
# Step 7: GitHub Secret Setup
#==============================================================================
echo -e "${BLUE}Step 7: GitHub Secret Setup${NC}"
echo "----------------------------------------"
echo ""
echo "To enable GitHub Actions deployments, you need to add a Railway API token"
echo "as a GitHub repository secret."
echo ""
echo "1. Generate a Railway API token:"
echo -e "   ${BLUE}https://railway.app/account/tokens${NC}"
echo ""
echo "   - Click 'Create Token'"
echo "   - Give it a name (e.g., 'github-actions')"
echo "   - Copy the generated token"
echo ""
echo "2. Add the token to GitHub Secrets:"
echo -e "   ${BLUE}https://github.com/<owner>/<repo>/settings/secrets/actions/new${NC}"
echo ""
echo -e "   - Name: ${YELLOW}RAILWAY_TOKEN${NC}"
echo -e "   - Secret: ${YELLOW}<paste-your-token>${NC}"
echo ""

#==============================================================================
# Summary
#==============================================================================
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}  Setup Complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "Your Railway infrastructure is ready. Next steps:"
echo ""
echo "  1. Add RAILWAY_TOKEN to GitHub secrets"
echo ""
echo "  2. Deploy by pushing to main:"
echo -e "     ${YELLOW}git add . && git commit -m \"Add Railway config\" && git push${NC}"
echo ""
echo "Useful commands:"
echo -e "  ${YELLOW}railway status${NC}       - Check project status"
echo -e "  ${YELLOW}railway logs${NC}         - View service logs"
echo -e "  ${YELLOW}railway open${NC}         - Open Railway dashboard"
echo -e "  ${YELLOW}railway variables${NC}    - View environment variables"
echo -e "  ${YELLOW}railway service link <name>${NC} - Switch to a service"
echo ""
