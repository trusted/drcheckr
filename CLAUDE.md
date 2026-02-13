# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is drcheckr

A Ruby gem that tracks dependencies across Docker images, checks for version updates, locks versions, and generates Dockerfiles from ERB templates. Configuration is YAML-driven (`drcheckr.yml` + `drcheckr-lock.yml`).

## Common Commands

```bash
# Run tests (preferred: via Docker)
docker build -t drcheckr-test . && docker run --rm drcheckr-test

# Run tests directly (requires Ruby 3.2+)
bundle install
bundle exec rake test

# Run a single test file
bundle exec ruby -Ilib test/bin/drcheckr_test.rb

# CLI usage
bin/drcheckr-cli check    # Check if deps are up to date (exit 122 if outdated)
bin/drcheckr-cli update   # Update versions in lock file
bin/drcheckr-cli gen      # Generate Dockerfiles from templates
```

## Architecture

**Entry points:** `bin/drcheckr` (shell wrapper handling Ruby version managers) → `bin/drcheckr-cli` (Ruby entry point) → `Drcheckr::Cli`

**Core flow:** CLI parses args → `Checkrfile` loads YAML config/lock files → Commands execute:

- `Commands::UpdateChecker` — queries version APIs (GitHub releases/Atom, Chrome Version History, EndOfLife.date, fixed), compares with locked versions, updates lock file
- `Commands::GenDockerfile` — builds template context via `ContextData`/`VariableLoader`, renders ERB templates through `Generator::ContainerFileGenerator` (uses Tilt)
- `Commands::ExpressionEvaluator` — evaluates standalone ERB expressions with dependency context

**Key classes:**
- `Checkrfile` — loads and caches `drcheckr.yml` and `drcheckr-lock.yml`
- `ContextData` — assembles template binding from dependencies + variables (exposes `{dep}_version` as `VersionNumber` objects)
- `VersionNumber` — semantic version parser with `major`/`minor`/`patch` accessors, handles `v` prefix

## Conventions

- All files use `# frozen_string_literal: true`
- All classes nested under `Drcheckr` module; commands under `Drcheckr::Commands`
- Exit code 122 means "outdated dependencies"
- `CHECKRFILE` env var overrides default config file path
- No linter configured; no `.rubocop.yml`
- CI tests against Ruby 3.4 and 4.0 (`.github/workflows/test.yml`)
