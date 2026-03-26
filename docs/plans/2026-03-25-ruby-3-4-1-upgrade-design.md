# Ruby 3.4.1 Upgrade Design

## Goal

Upgrade the application from Ruby `3.2.6` to Ruby `3.4.1` and make the project runnable and testable on that version with the minimum necessary dependency and configuration changes.

## Current State

- `.ruby-version` pins Ruby `3.2.6`.
- [`/home/mr_bowtie/Programming/ruby/iron_tusk_toolbox/Dockerfile`](/home/mr_bowtie/Programming/ruby/iron_tusk_toolbox/Dockerfile) and [`/home/mr_bowtie/Programming/ruby/iron_tusk_toolbox/Dockerfile.development`](/home/mr_bowtie/Programming/ruby/iron_tusk_toolbox/Dockerfile.development) both pin Ruby `3.2.6`.
- `Gemfile` does not currently declare a Ruby version.
- `Gemfile.lock` was generated for the existing runtime and will need to be refreshed under Ruby `3.4.1`.

## Approach

Use a conservative runtime upgrade:

1. Pin Ruby `3.4.1` anywhere the project currently pins the interpreter.
2. Add an explicit Ruby requirement in `Gemfile` so Bundler enforces the intended runtime.
3. Re-resolve the bundle on Ruby `3.4.1`.
4. Run project verification commands and only change gems or config if they block install, boot, build, or tests.

This keeps the change set narrow and avoids unrelated dependency churn.

## Compatibility Expectations

- Bundler may update `Gemfile.lock` metadata and platform-specific gem variants.
- Some gems with native extensions or stdlib assumptions may require patch-level upgrades for Ruby `3.4.1`.
- Docker images should use the same Ruby version as local development to avoid drift.

## Testing Strategy

Verify the upgrade in this order:

1. `bundle install` under Ruby `3.4.1`
2. `yarn build`
3. `bundle exec rspec`
4. `bin/rails test`

If one of these fails because of Ruby `3.4.1` compatibility, make the smallest change necessary and rerun the affected verification.

## Risks

- Ruby `3.4.1` may expose deprecations or removed defaults that were silent on `3.2.6`.
- Native gem builds may require lockfile or dependency refreshes.
- The local environment may not already have Ruby `3.4.1`, which would block lockfile regeneration until installed.
