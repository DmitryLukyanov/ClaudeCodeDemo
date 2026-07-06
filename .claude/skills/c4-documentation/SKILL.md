---
name: c4-documentation
description: >
  Produce C4-model architecture documentation (L1 Context, L2 Container, L3 Component,
  Deployment) as raw-text diagrams. Use when documenting or reverse-engineering a system's
  architecture in C4 notation. Invoke this skill whenever someone asks for architecture docs,
  C4 diagrams, system context diagrams, container maps, component diagrams, deployment diagrams,
  or wants to document how a system is structured — even if they don't say "C4" explicitly.
---

# C4 Architecture Documentation

## Inputs

This skill can run in two modes:

- **Facts provided by a caller** (e.g. an orchestrator command that already ran analysis):
  use those facts as the source of truth and do **not** re-scan the codebase. This keeps
  multiple documents rendered from the same facts mutually consistent.
- **No facts provided** (standalone use): gather them yourself from the codebase in the
  current working directory using the Discovery Checklist below.

Then render them in C4 notation.

---

## Output Files

Write four files under `docs/c4/`:

| File | C4 Level |
|---|---|
| `docs/c4/context.md` | L1 System Context |
| `docs/c4/container.md` | L2 Container |
| `docs/c4/component.md` | L3 Component |
| `docs/c4/deployment.md` | Deployment |

Each file follows this structure:
1. **Prose intro** — one short paragraph describing scope and purpose of this view.
2. **Text diagram** — ASCII art using the fixed legend below.
3. **Element & relationship key** — a table listing every box and arrow in the diagram with a one-line description.

---

## Fixed Legend (use identically across all four files)

```
People / Actors
  [ Person Name ]           Human user or role

System / Container / Component boxes
  +---------------------------+
  |  Name                     |
  |  [type: Technology]       |   ← technology tag only at L2+
  |  Short responsibility      |   ← responsibility line only at L3
  +---------------------------+

Relationships (inside system boundary)
  ──────────────────────>   label: protocol or action

Relationships crossing the system boundary
  ====================>   label: protocol or action

External systems (outside boundary)
  +===========================+
  |  Name                     |
  |  [External System]        |
  +===========================+
```

Re-use this legend verbatim — paste it at the top of each diagram section. This lets any reader orient themselves without switching files.

---

## C4 Levels — What Belongs Where

### L1 System Context (`context.md`)

The highest-altitude view. Show the system as **a single box**. Do not open it up.

Include:
- The system itself (one box, no internal detail)
- People / actors who interact with it directly
- External systems it sends to or receives from

Keep it sparse. If in doubt, leave it out. A good L1 fits on a terminal screen.

```
[ End User ]                    [ Admin ]

        |  uses (HTTPS)              | manages (HTTPS)
        v                            v
+------------------------------------------+
|  Your System                             |
|  [System]                                |
+------------------------------------------+
        |                            |
        | reads/writes (REST)        | sends events (AMQP)
        v                            v
+==================+       +==================+
|  PostgreSQL DB   |       |  Message Broker  |
|  [External DB]   |       |  [External SaaS] |
+==================+       +==================+
```

### L2 Container (`container.md`)

Zoom into the system boundary. Each box is a **separately deployable or runnable unit** — a process, service, database, queue, or storage bucket. Do not show classes or functions.

Each box must include:
- Name
- `[type: Technology]` tag (e.g., `[Service: Node.js]`, `[Database: PostgreSQL]`, `[Queue: RabbitMQ]`)

Label every relationship with its protocol or mechanism (HTTP, gRPC, SQL, AMQP, etc.).

```
+------------------------------------------+  (System boundary)
|                                          |
|  +------------------+  +-------------+  |
|  |  Web App         |  |  API Server |  |
|  |  [SPA: React]    |  |  [Service:  |  |
|  +------------------+  |   .NET]     |  |
|         |   HTTP/REST   +-------------+  |
|         +-------------->       |          |
|                          SQL   |          |
|                          v     v          |
|                  +-----------------+      |
|                  |  Database       |      |
|                  |  [DB: Postgres] |      |
|                  +-----------------+      |
+------------------------------------------+
```

### L3 Component (`component.md`)

Zoom into each significant container individually. Each box is a **major logical component** — a module, service class, or subsystem within that container. Still no individual functions or files.

Each box must include:
- Name
- Short responsibility (one line)

One diagram per container that has meaningful internal structure. Containers that are trivial (e.g., a plain DB with no logic) can be described in prose instead.

### Deployment (`deployment.md`)

The physical picture: infrastructure nodes and which containers run on them. Focus on **where** things run, not what they do.

Include:
- Infrastructure nodes (cloud regions, VMs, Kubernetes clusters, CDNs)
- Which container(s) run on each node
- Network paths between nodes, labeled with protocol

```
+--------------------+      +----------------------+
|  AWS us-east-1     |      |  CloudFront CDN      |
|                    |      |  [External: AWS]     |
|  +-------------+   |      +----------------------+
|  | ECS Cluster |   |               |
|  |             |   |   serves (HTTPS)
|  | [API Server]|   |               |
|  | [Worker]    |   |<--------------+
|  +-------------+   |
|  +-------------+   |
|  | RDS Instance|   |
|  | [Postgres]  |   |
|  +-------------+   |
+--------------------+
```

**Skip the L4 / code level** unless explicitly requested. It adds noise without C4 value at the documentation level.

---

## Altitude Discipline

The most common mistake is leaking detail from a lower level into a higher one.

| Level | Right altitude | Wrong altitude |
|---|---|---|
| L1 | "System talks to Stripe" | "API service calls Stripe via HTTP POST /charges" |
| L2 | "API Server [Service: .NET]" | "OrderController calls PaymentService" |
| L3 | "Payment Module — handles billing" | "Validates card number with Luhn algorithm" |
| Deployment | "ECS Cluster runs API Server" | "API Server listens on port 8080" |

If a detail feels relevant at a given level, ask: "Would this change if I redesigned the internals without changing the external behavior?" If yes, it belongs at a lower level or not at all.

---

## Discovery Checklist

Before writing any diagram, gather these facts from the codebase:

- **Actors**: Who uses the system? Check READMEs, auth code, and onboarding docs.
- **External systems**: What APIs, databases, queues, or SaaS products does the system call? Check config files, env var references, HTTP clients, and connection strings.
- **Containers**: What processes are deployed? Check `Dockerfile`s, `docker-compose.yml`, Kubernetes manifests, `package.json` / `.csproj` / `pom.xml` roots, and CI/CD deploy scripts.
- **Components**: What are the major internal modules? Check directory structure, entry points, and import graphs.
- **Infrastructure**: Where does it run? Check Terraform / Bicep / CloudFormation, README deploy sections, and CI/CD pipelines.

Use what you find; do not invent. Where information is genuinely unknown, write `[unknown]` in the diagram and note it in the key.
