# Docker Restart Recovery Design

## Problem

After a host power loss, the Compose stack restarts but the Rails web container can start before Postgres is accepting connections. The current web entrypoint also reinstalls JavaScript and Ruby dependencies on every boot, which makes restarts slow and causes Bundler to repopulate gems repeatedly.

## Goals

- Make the web container wait until Postgres is ready before running Rails database preparation or app processes.
- Keep Bundler-installed gems available across container restarts.
- Keep the fix limited to development container and Compose boot configuration.

## Recommended Approach

Use a defensive web entrypoint that waits on `pg_isready`, then runs `bundle exec rails db:prepare`, then starts `foreman`. Remove `bundle install` and `yarn install` from runtime boot. Keep Bundler installing into the image’s default `/usr/local/bundle` path and do not mask it with a named volume.

This protects the app from unclean restart timing even if Compose starts the web container before Postgres is ready. A Compose healthcheck can be added as a secondary signal, but the entrypoint wait loop remains the primary recovery mechanism. Avoiding a gem volume also prevents stale Docker volume contents from hiding the image-installed Rails executables.

## Tradeoffs

- Startup becomes slightly slower when Postgres is cold-starting, because the web container blocks until the database is ready.
- If dependencies change, the image or an explicit install command must refresh the bundle cache rather than relying on container boot side effects.

## Files

- Modify `docker-entrypoint.sh`
- Modify `docker-compose.yml`
- Modify `Dockerfile.development`
