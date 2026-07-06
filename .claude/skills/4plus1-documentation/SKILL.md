---
name: 4plus1-documentation
description: >
  Produce Kruchten 4+1 architecture documentation (Logical, Process, Development, Physical,
  Scenarios) as raw-text diagrams. Use when documenting a system's architecture in the 4+1
  view model. Invoke this skill whenever someone asks for 4+1 views, Kruchten diagrams,
  logical/process/development/physical views, runtime concurrency diagrams, or wants a
  use-case-driven architecture description — even if they don't say "4+1" explicitly.
---

# 4+1 Architecture Documentation

## Inputs

This skill can run in two modes:

- **Facts provided by a caller** (e.g. an orchestrator command that already ran analysis):
  use those facts as the source of truth and do **not** re-scan the codebase. This keeps
  multiple documents rendered from the same facts mutually consistent.
- **No facts provided** (standalone use): gather them yourself from the codebase in the
  current working directory using the Discovery Checklist below.

Then render them in the 4+1 view model.

---

## Output Files

Write five files under `docs/4plus1/`:

| File | View |
|---|---|
| `docs/4plus1/logical.md` | Logical view |
| `docs/4plus1/process.md` | Process view |
| `docs/4plus1/development.md` | Development view |
| `docs/4plus1/physical.md` | Physical view |
| `docs/4plus1/scenarios.md` | Scenarios (+1) |

Each file follows this structure:
1. **Prose intro** — one short paragraph: what this view shows and who its primary audience is.
2. **Text diagram** — ASCII art using the fixed legend below.
3. **Element & relationship key** — a table listing every symbol in the diagram with a one-line description.

---

## Fixed Legend (use identically across all five files)

This notation is deliberately UML-flavored to distinguish it from C4 box notation. Paste this block verbatim at the top of each diagram section.

```
Actors / External Agents
  (( Actor Name ))              human user, external system, or timer

Component / Object / Subsystem
  .-----------------------.
  | Name                  |
  | <<stereotype>>        |    stereotype: service, module, subsystem, controller, etc.
  '-----------------------'

Infrastructure Node  (Physical view only)
  [[ Node Name                ]]

Relationships
  ─────────────────>   label          synchronous call / association
  - - - - - - - - ->   label          dependency / uses / sends-to (async)
  ════════════════>   label          IPC / queue message / event
```

---

## The Five Views

### Logical View (`logical.md`)

**What it shows:** The functional decomposition of the system — the key abstractions, their responsibilities, and the structural relationships between them. Think: subsystems, components, and the main classes or services that define the design.

**Audience:** Developers and architects reasoning about the design's correctness and maintainability.

**What to include:**
- Major subsystems and the components inside each
- Key stereotypes: `<<service>>`, `<<repository>>`, `<<gateway>>`, `<<controller>>`, etc.
- Structural relationships: calls, inherits, uses, publishes

**What to leave out:** Runtime behavior (that's the Process view), source files or build units (Development view), and deployment nodes (Physical view).

```
.----------------------.         .----------------------.
| OrderService         |         | PaymentService       |
| <<service>>          |         | <<service>>          |
'----------------------'         '----------------------'
        |                                 ^
        | - - - - - charges - - - - - - ->|
        |
        v
.----------------------.         .----------------------.
| OrderRepository      |         | NotificationGateway  |
| <<repository>>       |         | <<gateway>>          |
'----------------------'         '----------------------'
```

---

### Process View (`process.md`)

**What it shows:** The runtime concurrency picture — which processes and threads exist, how they are scheduled, how they communicate, and how work flows through the system at runtime. This is the view where C4 is weakest; make it strong here.

**Audience:** Developers debugging race conditions, performance engineers, and anyone reasoning about reliability or ordering guarantees.

**What to include:**
- Every distinct OS process or container runtime (name + tech)
- Threads, goroutines, async event loops, or worker pools that have distinct lifetimes
- Scheduled / cron jobs and message consumers as named process boxes
- IPC mechanisms: HTTP calls, queue publishes/consumes, shared memory, signals
- Show startup/shutdown ordering if it matters

**What to leave out:** Source code structure (Development), deployment topology (Physical). Keep it dynamic — if it only exists at runtime, it belongs here.

Use `════>` (double-line arrows) for queue/IPC messages to make async flows immediately visible.

```
  (( Cron ))                                        (( User Browser ))
       |                                                    |
       | fires 09:00                                        | HTTP POST /orders
       v                                                    v
.-------------.    ════ order.created ════>    .---------------------.
| Job Runner  |                               | API Process          |
| <<process>> |                               | <<process: Node.js>> |
'-------------'                               '---------------------'
                                                        |
                                          - - enqueue - ->
                                                        v
                                              .-------------------.
                                              | Worker Process    |
                                              | <<process: Node>> |
                                              '-------------------'
                                                        |
                                              ════ email.send ════>
                                                        v
                                              .-------------------.
                                              | Mailer Process    |
                                              | <<process: SMTP>> |
                                              '-------------------'
```

---

### Development View (`development.md`)

**What it shows:** How the codebase is organized into build units — packages, modules, libraries, layers — and the dependency relationships between them. The goal is to make layering, coupling, and build order visible.

**Audience:** Developers navigating the codebase, build engineers, and anyone reviewing dependencies.

**What to include:**
- Source packages, modules, or directories as named boxes (stereotype: `<<package>>`, `<<layer>>`, `<<lib>>`, etc.)
- Dependency arrows pointing from dependent → dependency (show the direction explicitly)
- Layer separators where the architecture enforces a boundary (e.g., domain must not depend on infrastructure)
- External libraries or SDKs that the codebase depends on

**What to leave out:** Runtime behavior, deployment nodes, individual files unless they represent an architectural boundary.

Show layers top-to-bottom with the most abstract at the top:

```
             ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
               Presentation Layer
             │  .-------------.             │
                | web/        |
             │  | <<package>> |             │
                '-------------'
             └ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─┘
                         | depends on
             ┌ ─ ─ ─ ─ ─ v ─ ─ ─ ─ ─ ─ ─ ─ ┐
               Application Layer
             │  .-------------.             │
                | app/        |
             │  | <<package>> |             │
                '-------------'
             └ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─┘
                         | depends on
             ┌ ─ ─ ─ ─ ─ v ─ ─ ─ ─ ─ ─ ─ ─ ┐
               Domain Layer  (no upward deps)
             │  .-------------.             │
                | domain/     |
             │  | <<package>> |             │
                '-------------'
             └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

---

### Physical View (`physical.md`)

**What it shows:** The deployment topology — real infrastructure nodes, the network zones between them, and which processes run where. This is the ops and security engineer's view.

**Audience:** DevOps, infrastructure engineers, and security reviewers.

**What to include:**
- Infrastructure nodes (`[[ ]]` notation), labeled with cloud provider / type if known
- Network segments or zones (Internet, DMZ, private subnet — use fenced regions in ASCII)
- Which process (from the Process view) runs on each node
- Network edges labeled with protocol, port, and direction
- Load balancers, CDNs, and gateways as their own nodes

**What to leave out:** Internal component detail (Logical view) and source structure (Development view). Keep it at the infrastructure level.

```
  Internet Zone
  ─────────────────────────────────────────────────────────
  (( Browser ))
        |  HTTPS :443
        v
  [[ CDN / WAF                     ]]
        |  HTTPS :443
  ─────|───────────────────────────── DMZ ─────────────────
        v
  [[ Load Balancer                 ]]
        |  HTTP :8080
  ─────|───────────────────────────── Private Subnet ──────
        v
  [[ App Server (EC2 / t3.medium)  ]]   runs: API Process, Worker Process
        |  TCP :5432          |  AMQP :5672
        v                     v
  [[ RDS PostgreSQL           ]]   [[ RabbitMQ (MQ broker) ]]
```

---

### Scenarios (+1) (`scenarios.md`)

**What it shows:** A small set of key use cases — typically 3–5 — that trace execution across all four views. Scenarios are the glue: they validate that the other four views work together and expose gaps.

**Audience:** Everyone. Scenarios are the most readable entry point to the architecture.

**What to include:**
- The most architecturally significant use cases (not the most common — the ones that exercise the most cross-cutting interaction)
- One sequence diagram per scenario using the format below
- A one-sentence summary above each diagram naming the views it touches

**Sequence diagram format:** Named lifelines across the top, vertical bars, labeled horizontal arrows, dashed return arrows. Keep it to one terminal screen wide.

```
Scenario: Place an Order (touches Logical, Process, Physical)

  Browser       API Proc      OrderSvc      PaymentSvc    DB
     |              |             |              |          |
     |--POST /order>|             |              |          |
     |              |--place()--->|              |          |
     |              |             |--charge()---->|          |
     |              |             |              |--INSERT-->|
     |              |             |              |<- - ok - -|
     |              |             |<- - paid- - -|          |
     |              |             |--INSERT order----------->|
     |              |             |<- - - - - - id - - - - -|
     |              |<- - 201- - -|              |          |
     |<- - 201 - - -|             |              |          |
```

Return arrows use `<- - -` (dashed left-pointing). Synchronous calls use `-->` or `─>`. Async sends use `═══>`. Column alignment matters — keep lifelines evenly spaced so the vertical flow is readable.

Choose scenarios that together exercise:
- The happy path for the system's primary purpose
- A significant async / background flow (shows the Process view at work)
- An error or boundary condition that reveals how views interact under failure

---

## Discovery Checklist

Before writing any diagram, gather these facts from the codebase:

- **Logical:** Directory structure, key source files, class/interface names, stereotypes visible in naming conventions (`*Service`, `*Repository`, `*Controller`, `*Gateway`).
- **Process:** Entrypoints (`main`, `cmd/`, top-level scripts), Dockerfile `CMD`/`ENTRYPOINT`, cron definitions, queue consumer registrations, async job frameworks.
- **Development:** `go.mod`, `package.json`, `pom.xml`, `.csproj`, `requirements.txt` — these define build units and external dependencies. Import graphs in key files reveal layering.
- **Physical:** `docker-compose.yml`, Kubernetes manifests, Terraform / Bicep / CloudFormation, CI/CD deploy steps, README deploy sections.
- **Scenarios:** README user stories, test names (integration tests often name the scenario), API route definitions, acceptance test files.

Use what you find; do not invent. Mark unknowns as `[unknown]` in the diagram and call them out in the key.
