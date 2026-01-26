# CI/CD Pipeline

This directory contains GitHub Actions workflows for the monorepo CI/CD pipeline.

## Pipeline Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   CI Pipeline   │────▶│  Build docker   │────▶│   CD - Deploy   │
│ (00-triggers)   │     │   (ci-build)    │     │ (cd-*)          │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
   Change detection        Build images           Deploy only
   & configuration      (reusable workflow)      (no build)
```

## Workflows

### CI Workflows (Build)

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `00-triggers.yml` | Push/PR to main/develop, workflow_dispatch | Detects changes, sets config, calls ci-build |
| `ci-build.yml` | workflow_call (from 00-triggers) | Builds Docker images using matrix strategy |

### CD Workflows (Deploy)

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `cd-production.yml` | After CI succeeds on main | Deploy to production (no build) |
| `cd-staging.yml` | After CI succeeds on develop | Deploy to staging (no build) |
| `cd-preview.yml` | Pull Request | Build + deploy PR preview (has own build) |

### Reusable Workflows

| Workflow | Description |
|----------|-------------|
| `_build.yml` | Docker image build with GHCR push |
| `_deploy.yml` | Railway deployment |
| `_notify.yml` | GitHub notifications (PR comments, releases) |
| `_cleanup.yml` | PR preview environment cleanup |

## Service Matrix

Services are defined in `service-matrix.yml`. The CI pipeline dynamically detects changes based on this configuration.

```yaml
# .github/service-matrix.yml
services:
  - image-name: php-api
    dockerfile: ./docker/Dockerfile.php-api
    context: .
    platforms: linux/amd64
    source-path: php-services

  - image-name: go-api
    dockerfile: ./docker/Dockerfile.go-api
    context: .
    platforms: linux/amd64
    source-path: go-services
```

**To add a new service:** Simply add an entry to `service-matrix.yml` - no workflow changes needed.

## Job Display Names

The CI pipeline displays jobs as:

```
CI Pipeline
└── Build Images
    └── Build docker
        ├── php-api
        └── go-api
```

## Environment Flow

```
Feature Branch ──▶ PR Preview ──▶ develop ──▶ Staging ──▶ main ──▶ Production
                   (build+deploy)  (CI build)  (deploy)   (CI build) (deploy)
                   (auto-cleanup)
```

## Versioning

| Environment | Version Format | Example |
|-------------|----------------|---------|
| Production | Semantic (auto-increment) | `v1.2.3` |
| Staging | Build number | `v1.0.0-staging.123` |
| Preview | PR + commit | `pr-42-abc1234` |

Production versioning follows conventional commits:
- `BREAKING CHANGE` → Major bump
- `feat:` → Minor bump
- `fix:` → Patch bump

## GitHub Actions Summary

Each workflow step generates a summary visible in the Actions UI:

### Setup Job Summary
- Environment (production/staging/preview)
- Version tag
- Branch name
- Changed services

### Build Matrix Summary
- Input parameters
- Services to build (table)
- Build status

### Build Job Summary (per image)
- Configuration (image name, dockerfile, platform, etc.)
- Generated image tags
- Build result with digest

## Required Secrets

| Secret | Description |
|--------|-------------|
| `RAILWAY_TOKEN` | Railway API token |
| `RAILWAY_PROJECT_ID` | Railway project ID |

## CODEOWNERS

Team ownership is defined in `CODEOWNERS`:

| Path | Team |
|------|------|
| `.github/workflows/` | @twaydev/devops-team |
| `/php-services/` | @twaydev/php-team |
| `/go-services/` | @twaydev/go-team |
| `/rust-services/` | @twaydev/rust-team |
| `/frontend/` | @twaydev/frontend-team |
| `/docs/`, `README.md` | @twaydev/tech-lead |

## Directory Structure

```
.github/
├── CODEOWNERS              # Team ownership rules
├── README.md               # This file
├── service-matrix.yml      # Service definitions for CI
└── workflows/
    ├── 00-triggers.yml     # CI entry point & change detection
    ├── ci-build.yml        # CI build (reusable, matrix)
    ├── cd-production.yml   # Production deployment
    ├── cd-staging.yml      # Staging deployment
    ├── cd-preview.yml      # PR preview (build + deploy)
    ├── _build.yml          # Reusable: Docker build
    ├── _deploy.yml         # Reusable: Railway deploy
    ├── _notify.yml         # Reusable: Notifications
    └── _cleanup.yml        # Reusable: Cleanup
```
