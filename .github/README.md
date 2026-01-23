# CI/CD Pipeline

This directory contains GitHub Actions workflows for the monorepo CI/CD pipeline.

## Pipeline Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Trigger Setup  │────▶│   CI - Build    │────▶│   CD - Deploy   │
│ (00-triggers)   │     │   (ci-build)    │     │ (cd-*)          │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
   Change detection        Build images           Deploy only
   & configuration         (matrix)              (no build)
```

## Workflows

### CI Workflows (Build)

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `00-triggers.yml` | Push to main/develop | Detects changes and sets build configuration |
| `ci-build.yml` | workflow_run (Trigger Setup) | Builds Docker images using matrix strategy |

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

## Build Matrix (CI only)

CI workflow builds the following images in parallel:

| Image | Dockerfile |
|-------|------------|
| `php-api` | `./docker/Dockerfile.php-api` |
| `go-api` | `./docker/Dockerfile.go-api` |

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
└── workflows/
    ├── 00-triggers.yml     # Trigger setup & change detection
    ├── ci-build.yml        # CI build (matrix)
    ├── cd-production.yml   # Production deployment (deploy only)
    ├── cd-staging.yml      # Staging deployment (deploy only)
    ├── cd-preview.yml      # PR preview (build + deploy)
    ├── _build.yml          # Reusable: Docker build
    ├── _deploy.yml         # Reusable: Railway deploy
    ├── _notify.yml         # Reusable: Notifications
    └── _cleanup.yml        # Reusable: Cleanup
```
