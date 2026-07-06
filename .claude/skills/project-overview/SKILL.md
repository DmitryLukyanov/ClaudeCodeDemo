---
name: project-overview
description: >
  Produce a project overview.md (goal, technologies, sequence flows, external references,
  build/run steps) from codebase analysis. Use when creating a high-level overview of a
  project. Invoke this skill whenever someone asks for a project overview, README, project
  summary, onboarding document, "what does this project do", tech stack summary, or wants
  to understand how to build and run a codebase — even if they don't say "overview" explicitly.
---

# Project Overview

## Inputs

This skill can run in two modes:

- **Facts provided by a caller** (e.g. an orchestrator command that already ran analysis):
  use those facts as the source of truth and do **not** re-scan the codebase. This keeps
  the overview consistent with any other documents rendered from the same facts.
- **No facts provided** (standalone use): gather them yourself from the codebase in the
  current working directory using the Discovery Checklist below.

Then write the overview.

---

## Output File

Write a single file: `docs/overview.md`

The document is meant to be skimmable. A new team member or returning contributor should be able to read it top-to-bottom in five minutes and know what the system does, how to run it, and where everything connects. Favor short paragraphs and clear headings over exhaustive prose.

---

## Required Section Contract

Produce these sections in this order. Do not skip a section; if information is genuinely unavailable, write a short note explaining that rather than omitting the heading.

---

### 1. Goal / Purpose

One or two paragraphs in plain language: what does this system do, for whom, and why does it exist? Avoid jargon. If there is a mission statement, product brief, or top-level README, draw from it. If not, infer from the entry points, route names, and domain model.

Keep altitude high — this is the "elevator pitch", not a feature list.

---

### 2. Technologies Used

A concise reference table covering every significant technology in the stack. Readers use this to orient themselves before diving into code.

Format as a markdown table:

| Category | Technology | Version / Notes |
|---|---|---|
| Language | Go | 1.22 |
| Web framework | Gin | v1.9 |
| Database | PostgreSQL | 15, via pgx driver |
| Queue | RabbitMQ | AMQP 0-9-1 |
| Auth | Auth0 | JWT RS256 |
| Build | Docker + Make | multi-stage image |

Populate from: `go.mod`, `package.json`, `pom.xml`, `.csproj`, `requirements.txt`, `Gemfile`, `Dockerfile`, `docker-compose.yml`, CI/CD pipelines, and any `.tool-versions` / `.nvmrc` / `.python-version` files.

Include runtime version (Node 20, Python 3.11, JDK 21, etc.) — this is the single most useful thing for a new developer setting up locally.

---

### 3. Runtime / Process Notes

Short prose (3–6 sentences) describing what actually runs at runtime: how many processes, what their roles are, whether there are background workers, scheduled jobs, or long-running consumers. If the architecture is simple (one process), say so briefly. If it is complex (multiple services, workers, cron jobs), name each and describe its role.

This section bridges the "what it is" (Goal) and the "how it flows" (Sequence schema) sections. It is prose, not a diagram — save diagrams for the next section.

Examples of things to mention:
- "The API server handles inbound HTTP; a separate worker process consumes jobs from the Redis queue."
- "A cron job runs nightly at 02:00 UTC to aggregate daily metrics."
- "All processing is single-process, single-threaded; async I/O via Node.js event loop."

---

### 4. Sequence Schema

Show the 2–4 most architecturally significant end-to-end flows as raw-text sequence diagrams. The goal is to make the runtime behavior visible without requiring the reader to trace code.

Choosing flows: pick the ones that cross the most boundaries or carry the most risk — the happy-path entry point, a significant async flow, and an auth or error path if relevant. Not every feature needs a diagram.

**Sequence diagram format:**

```
  Lifeline1     Lifeline2     Lifeline3
      |              |              |
      |--message()-->|              |
      |              |--call()----->|
      |              |<- - result - |
      |<- - reply - -|              |
```

Rules:
- Name lifelines after the process, service, or actor — not a class name.
- Synchronous calls: `-->` pointing right.
- Return values: `<- -` pointing left (dashed to distinguish from calls).
- Async/queue sends: `═══>` double-line arrow.
- Keep diagrams to terminal width (~80 chars). If a flow is too wide, split it into two diagrams with a prose bridge.
- Precede each diagram with a one-sentence description of what scenario it illustrates.

---

### 5. External References

A structured list of everything the system connects to or depends on that lives outside this codebase.

Format as subsections:

**Datastores**
List each database, cache, or object store: name, type, what it holds.

**Third-party APIs & Services**
List each external API, SaaS platform, or cloud service: name, what it is used for, and the environment variable or config key that holds the credentials.

**Auth**
Describe the authentication mechanism: provider (if any), token format, where verification happens.

**Related repositories / docs / tickets**
Link to any companion repos, architecture decision records, Confluence/Notion pages, Jira epics, or Slack channels that provide context not in this repo. Use placeholder text `[link]` if a URL is unknown.

If a category has no entries, write "None" rather than omitting it — this signals that the absence is intentional.

---

### 6. How to Build / Run

Exact, copy-pasteable steps for a developer to get the system running locally from a clean checkout. Derive these from the actual build tooling found in the repo — do not invent generic steps.

Structure as numbered steps. Cover:
1. Prerequisites (runtime versions, global tools)
2. Install dependencies
3. Configure environment (point to `.env.example` or list required vars)
4. Start datastores / dependencies (Docker Compose if present)
5. Run the application
6. Run the tests

If there is a `Makefile`, list the relevant `make` targets. If there is a `docker-compose.yml` with a dev profile, show how to use it. If there is an existing `CONTRIBUTING.md` or `DEVELOPMENT.md`, reference it rather than duplicating it.

---

## Discovery Checklist

Before writing, gather from the codebase:

- **Goal:** Top-level README, `package.json` description, any `docs/` or `wiki/` directory.
- **Technologies:** Dependency manifests (`go.mod`, `package.json`, `requirements.txt`, etc.), `Dockerfile`, `.tool-versions`.
- **Runtime/Process:** `Dockerfile` `CMD`/`ENTRYPOINT`, `docker-compose.yml` service definitions, cron/scheduler registrations, job queue consumer registration points.
- **Sequences:** Integration test names, API route definitions, controller/handler entry points — these often name the flows explicitly.
- **External references:** Environment variable references (`process.env.*`, `os.Getenv`, `os.environ`), HTTP client base URLs, connection string patterns.
- **Build/run:** `Makefile`, `package.json` scripts, `Taskfile.yml`, `.github/workflows/`, existing `CONTRIBUTING.md`.

Use what you find; do not invent. For anything genuinely unknown, write `[unknown]` so the reader knows it is a gap, not an omission.
