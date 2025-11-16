# Repository Guidelines

## Project Structure & Module Organization
- Entry point lives in `main.go`; CLI commands are in `cmd/` (e.g., `list.go`, `create.go`, `remove.go`).
- Core logic sits under `internal/` (`git/` for repository ops, `editor/` for editor detection, `ui/` for colors); reusable helpers go in `pkg/`.
- Documentation is in `docs/`; automation and release helpers are in `scripts/` (install, release manager, build utils).
- Tests live in `test/`. Build artifacts land in `build/` (local) and `dist/` (release). Homebrew taps are tracked in `homebrew-gwt/` and `homebrew-tap/`.

## Build, Test, and Development Commands
- `make init` downloads Go module dependencies.
- `make build` produces the CLI for the host platform; binary at `build/gwt`.
- `make run` runs the built binary; `make dev` uses `air` for hot reload when available.
- `make check` runs `fmt`, `vet`, and `lint`. `make test` runs unit tests; `make test-coverage` writes a coverage report; `make bench` runs benchmarks.
- Release-oriented: `make build-all` for all platforms, `make release` for production artifacts, `make completion` for shell completions.

## Coding Style & Naming Conventions
- Go code must be formatted with `gofmt`; keep imports tidy and avoid unchecked lint warnings (`golint`, `go vet`).
- Favor clear, small functions; follow Effective Go idioms. Use Go’s default tab indentation.
- Branch names: `feature/<name>`, `fix/<name>`, `docs/<name>`, `refactor/<name>`, `test/<name>`.

## Testing Guidelines
- Use Go’s testing package; place tests under `test/` or alongside code with `_test.go` suffix.
- Name tests `TestX`, benchmarks `BenchmarkX`, examples `ExampleX`.
- Expect ≥80% coverage for new work; add regression tests for bug fixes.
- Prefer table-driven tests and temporary repos for git-related cases.

## Commit & Pull Request Guidelines
- Commit messages follow Conventional Commits: `feat|fix|docs|style|refactor|test|chore(scope): summary`. Reference issues in the footer (e.g., `Closes #123`).
- Before opening a PR, run `make check` and `make test`; include coverage-sensitive areas in the diff.
- PRs should describe scope, testing performed, and any user-facing changes. Add screenshots or CLI output when behavior changes.

## Security & Configuration Tips
- Keep secrets out of the repo; scripts expect local Git creds and Go toolchains. Use `.env` or shell exports rather than committing tokens.
- For packaging, prefer `scripts/release-manager.sh interactive` over ad-hoc commands to ensure checksums and artifacts are consistent.
