# CI/CD Workflows

## Adding a New Service

To add a new service to the CI/CD pipeline, simply edit the `build-matrix.yml` file:

### Example: Adding a new service

```yaml
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

  - image-name: rust-api
    dockerfile: ./docker/Dockerfile.rust-api
    context: .
    platforms: linux/amd64
    source-path: rust-services
```

### Field Descriptions

- **image-name**: The name of the Docker image (used for tagging)
- **dockerfile**: Path to the Dockerfile relative to repository root
- **context**: Docker build context (usually `.` for repository root)
- **platforms**: Target platforms for the build (e.g., `linux/amd64`, `linux/arm64`)
- **source-path**: Directory containing the service source code

### How It Works

The CI workflow automatically:
1. Detects code changes by comparing git diffs
2. Checks if changes match: `^(source-path/|dockerfile|shared-schemas/)`
3. Only builds services where code has changed
4. Skips unchanged services to save CI time

### Change Detection Pattern

For each service, the workflow checks if any of these paths changed:
- `{source-path}/**` - Any file in the service directory
- `{dockerfile}` - The Dockerfile itself
- `shared-schemas/**` - Shared schema changes affect all services

This means:
- Changing `php-services/src/Controller.php` → rebuilds `php-api` only
- Changing `docker/Dockerfile.go-api` → rebuilds `go-api` only
- Changing `shared-schemas/user.proto` → rebuilds all services
