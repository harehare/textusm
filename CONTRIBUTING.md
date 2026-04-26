# Contributing to TextUSM

## Prerequisites

Install the following tools:

- [asdf](https://asdf-vm.com/) — manages Node.js, Go, Elm, and just versions
- [just](https://github.com/casey/just) — task runner (`asdf install`)
- [pnpm](https://pnpm.io/) — package manager (`npm install -g pnpm`)
- [Firebase CLI](https://firebase.google.com/docs/cli) — for local emulators

After installing asdf, run `asdf install` in the repo root to install the correct tool versions defined in `.tool-versions`.

## Local Development

```shell
# 1. Copy environment variables
cp .env.example .env
# Edit .env with your Firebase project credentials

# 2. Install frontend dependencies
cd frontend && pnpm install && cd ..

# 3. Start everything (frontend + backend + Firebase emulators)
just run
```

- Frontend: http://localhost:3000
- Backend API: http://localhost:8081
- Firebase Emulator UI: http://localhost:4000

## Project Structure

```
frontend/   Elm + TypeScript web application (Vite)
backend/    Go API server (chi, gqlgen, sqlc)
cli/        Node.js CLI tool (TypeScript, Puppeteer)
extension/  VSCode extension (Elm library)
```

## Running Tests

```shell
# All tests
just test

# Frontend unit tests only
cd frontend && pnpm test

# Backend tests only
cd backend && just test

# E2E tests (requires Firebase emulators running)
cd frontend && pnpm test:e2e
```

## Code Style

**Frontend (Elm)**
```shell
cd frontend
pnpm format:elm        # format
pnpm lint:elm          # lint (elm-review)
```

**Frontend (TypeScript)**
```shell
cd frontend
pnpm format:ts         # format with oxfmt
pnpm lint:ts           # lint with oxlint
```

**Backend (Go)**
```shell
cd backend
just lint              # golangci-lint + gosec + staticcheck
```

## Making Changes

1. Create a branch from `master`
2. Make your changes with tests
3. Ensure `just test` passes and linters are clean
4. Open a pull request against `master`

## Release Process

Releases are fully automated:

1. Update the version in `frontend/package.json`
2. Merge the PR to `master`
3. `create_tag.yml` automatically creates a git tag (`v<version>`)
4. The tag push triggers `deploy.yml`, which builds and deploys to production

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](./LICENSE).
