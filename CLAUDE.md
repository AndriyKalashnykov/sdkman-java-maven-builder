# CLAUDE.md

SDKMAN-based Docker image builder for Java/Maven development environments.

## Build / Test Commands

```bash
make help              # List available targets
make check-env         # Check environment variables and installed tools
make login             # Login to a registry
make build-inline-cache # Build remote cache for the SDKMAN! Java/Maven builder image
make build             # Build SDKMAN! Java/Maven builder image
make version           # Run 'maven version' on SDKMAN! Java/Maven builder image
make it                # Run SDKMAN! Java/Maven builder image interactively
make push              # Push builder image to a registry
make delete            # Delete builder image locally
make cleanup           # Cleanup docker images, containers, volumes, networks, build cache
make build-sample      # Build sample image
make start-sample      # Start sample image
make test-sample       # Test sample image
make stop-sample       # Stop sample image
make delete-sample     # Delete sample image locally
```

## Architecture

- Base image: `debian:bookworm-slim` (Debian 12)
- Java: Eclipse Temurin via SDKMAN (default: 21.0.10-tem)
- Maven: 3.9.14 via SDKMAN
- Pack CLI: v0.40.2 (Cloud Native Buildpacks)
- CI builds three Java variants: 21 (LTS), 17 (LTS), 11 (LTS)

## Skills

| File(s) | Skill |
|---------|-------|
| `CLAUDE.md` | `/claude` |
| `Makefile` | `/makefile` |
| `README.md` | `/readme` |
| `.github/workflows/*.yml` | `/ci-workflow` |
| `Dockerfile` | Docker image build |

## Improvement Backlog

- Add renovate.json for automated dependency updates
- Migrate sample/Dockerfile to use a maintained Tomcat base image (bitnami-tomcat9-jdk18 may be EOL)
- Consider multi-stage build optimization to reduce final image size
- Add health check to Dockerfile
- Consider adding `make ci` target for local CI validation
- Evaluate replacing `build-inline-cache` with GitHub Actions cache (type=gha) for all builds
