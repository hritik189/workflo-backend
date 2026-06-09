# api — Task Board service

A REST API for managing task boards, built with **TypeScript, Express, and Mongoose/MongoDB**,
with JWT cookie authentication. This is the primary workload of the [Workflo platform](../../README.md).

- [Run it](#run-it)
- [Environment variables](#environment-variables)
- [Scripts](#scripts)
- [API endpoints](#api-endpoints)
- [Project structure & conventions](#project-structure--conventions)
- [Container & deploy](#container--deploy)

## Run it

### With Docker Compose (recommended — includes MongoDB)

From the repository root:

```sh
docker compose up --build
# api is now on http://localhost:8080
```

### Directly (needs a running MongoDB)

```sh
cd apps/api
npm install
npm run dev           # hot-reload dev server on PORT (default 8080)
```

Create a `.env` file in `apps/api/` (loaded automatically) — see variables below.

## Environment variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `DB_URL` | yes | — | MongoDB / Cosmos connection string. The database name is fixed to `workflo_DB`. |
| `JWT_SECRET` | yes | — | Secret used to sign JWTs. |
| `PORT` | no | `8080` | Port the server listens on. |
| `ORIGIN` | no | — | Allowed CORS origin (note: the dev CORS list is currently hardcoded to localhost:3000 / :5173). |
| `NODE_ENV` | no | `development` | `production` makes the auth cookie `secure`. |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | no | — | When set, exports telemetry to Application Insights; no-op otherwise. |

Example `.env`:

```env
PORT=8080
DB_URL=mongodb://localhost:27017
JWT_SECRET=replace-me
ORIGIN=http://localhost:3000
```

## Scripts

```sh
npm run dev         # hot-reload dev server (ts-node-dev, transpile-only)
npm run build       # compile TypeScript to dist/ (fails on type errors)
npm start           # run the compiled server (node dist/server.js)
npm run typecheck   # type-check only, no emit
npm run seed        # wipe & reseed the database (User + TaskBoard) — destructive
```

## API endpoints

### Health (used by Kubernetes probes)

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Liveness — always `200` while the process is up (DB-independent). |
| GET | `/ready` | Readiness — `200` only when MongoDB is connected, else `503`. |

### Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| POST | `/api/auth/signup` | — | Register a new user |
| POST | `/api/auth/login` | — | Log in (sets `access_token` cookie) |
| GET | `/api/auth/validate` | cookie | Validate the current session |
| POST | `/api/auth/logout` | cookie | Log out |

### Task boards (all require the auth cookie)

| Method | Path | Description |
|---|---|---|
| POST | `/api/task-board` | Create a task board |
| GET | `/api/task-board/:userId` | Get a user's task board |
| PUT | `/api/task-board/:userId` | Replace a board's tasks |
| DELETE | `/api/task-board/:userId/task/:taskId` | Delete one task |

Example create body:

```json
{
  "userId": "<user id>",
  "tasks": [
    { "title": "Task 1", "description": "…", "status": "To-Do",       "priority": "Medium", "deadline": "2024-07-29" },
    { "title": "Task 2", "description": "…", "status": "In Progress", "priority": "Urgent", "deadline": "2024-07-30" }
  ]
}
```

`status` ∈ `To-Do | In Progress | Under Review | Completed`; `priority` ∈ `Low | Medium | Urgent`.

## Project structure & conventions

```
apps/api/
├── server.ts              # entry point (telemetry → app.listen → dbConnect)
├── src/
│   ├── app/app.ts         # Express app + global middleware + /health, /ready
│   ├── routes/            # /api/auth and /api/task-board
│   ├── controllers/       # request handlers
│   ├── models/            # Mongoose models (User, TaskBoard)
│   ├── middleware/        # auth, CatchAsyncError, ErrorMiddleware
│   ├── utils/             # ErrorHandler, jwt
│   ├── config/            # env + dbConnect
│   └── telemetry.ts       # Azure Monitor OpenTelemetry (no-op without a connection string)
└── Dockerfile             # multi-stage, distroless, non-root
```

- **Errors**: handlers are wrapped in `CatchAsyncError` and throw via
  `next(new ErrorHandler(message, statusCode))`; a final `ErrorMiddleware` formats the response.
- **Auth**: JWT in an `httpOnly` `access_token` cookie; `isAuthenticated` loads `req.user`.
- **Data**: one `TaskBoard` per user with an embedded `tasks` array.

## Container & deploy

The `Dockerfile` builds a small distroless image. In the platform it's built and pushed by CI
([pipelines](../../pipelines/README.md)) and deployed to AKS by Helm
([deploy](../../deploy/README.md)); secrets come from Key Vault at runtime.
