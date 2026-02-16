#!/bin/bash

# Deployment script for workoflow integration platform
# Usage: ./scripts/deploy.sh {prod|stage}

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Validate environment parameter
ENV="${1:-}"

if [ -z "$ENV" ]; then
    log_error "Environment parameter is required"
    echo "Usage: $0 {prod|stage}"
    exit 1
fi

if [ "$ENV" != "prod" ] && [ "$ENV" != "stage" ]; then
    log_error "Invalid environment: $ENV"
    echo "Usage: $0 {prod|stage}"
    exit 1
fi

# Map environment to SSH host
if [ "$ENV" = "prod" ]; then
    HOST="val-workoflow-prod"
    ENV_NAME="Production"
    BRANCH="main"
else
    HOST="val-workoflow-stage"
    ENV_NAME="Staging"
    BRANCH="stage"
fi

echo ""
log_info "=========================================="
log_info "Deploying to: ${ENV_NAME} (${HOST})"
log_info "=========================================="
echo ""

# Check VPN connectivity by testing target host
log_info "Checking VPN and connection to ${HOST}..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$HOST" "exit" 2>/dev/null; then
    log_error "Cannot reach ${HOST}"
    log_error "Please ensure you are connected to the VPN:"
    echo "  sudo openvpn --config ~/nm-openvpn/patrick_schoenfeld@gateway.lfeld.nxs.rocks.ovpn"
    exit 1
fi
log_success "Successfully connected to ${HOST}"

# Execute deployment commands on remote server
log_info "Starting deployment process..."
echo ""

ssh -t "$HOST" DEPLOY_BRANCH="$BRANCH" bash << 'ENDSSH'
set -euo pipefail

# Colors for remote output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[REMOTE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[REMOTE]${NC} $1"
}

log_error() {
    echo -e "${RED}[REMOTE]${NC} $1"
}

log_info "Switching to docker user..."

sudo -iu docker DEPLOY_BRANCH="$DEPLOY_BRANCH" bash << 'DOCKEREOF'
set -euo pipefail

# Colors for docker user output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[DOCKER]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[DOCKER]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[DOCKER]${NC} $1"
}

log_info "Navigating to workoflow-integration-platform directory..."
cd /home/docker/docker-setups/workoflow-integration-platform

log_info "Current directory: $(pwd)"
log_info "Current branch: $(git branch --show-current)"

log_info "Fetching latest changes from git..."
git fetch origin

log_info "Resetting to match remote branch: ${DEPLOY_BRANCH}..."
git checkout "$DEPLOY_BRANCH"
git reset --hard "origin/${DEPLOY_BRANCH}"

log_success "Git sync completed successfully"

log_info "Running setup script..."
./setup.sh prod

log_success "Setup script completed successfully"

DOCKEREOF

ENDSSH

# Check if SSH command was successful
if [ $? -eq 0 ]; then
    echo ""
    log_success "=========================================="
    log_success "Deployment to ${ENV_NAME} completed!"
    log_success "=========================================="
    echo ""
    exit 0
else
    echo ""
    log_error "=========================================="
    log_error "Deployment to ${ENV_NAME} failed!"
    log_error "=========================================="
    echo ""
    exit 1
fi
