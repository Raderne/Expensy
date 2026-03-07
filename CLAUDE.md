# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Expensy** is a personal expense tracking application. This repo contains:
- `REM.Expensy/` — ASP.NET Core 10.0 Web API backend (monolith)
- `WebClients/` — Frontend client(s) (not yet implemented)
- `guides/` — Architecture and setup documentation

## Backend Commands

All commands run from `REM.Expensy/REM.Expensy.Backoffice/`:

```bash
dotnet build                                    # Build
dotnet run                                      # Run (HTTP: localhost:5118)
dotnet watch run                                # Run with hot reload

# EF Core migrations (from project directory)
dotnet ef migrations add <MigrationName>
dotnet ef database update
dotnet ef migrations remove                     # Remove last migration

dotnet test                                     # Run tests (no test projects yet)
```

**Launch profiles** (from `launchSettings.json`):
- `Project` — HTTP on `http://localhost:5118`
- `https` — HTTPS on `https://localhost:7212`
- `Container (Dockerfile)` — Docker on ports 8080/8081

**Swagger UI** is available at `/swagger` in development.

**Health check** endpoint: `/health` (checks PostgreSQL connectivity)

## Architecture

The backend uses **clean/layered architecture** in a single project (`REM.Expensy.Backoffice`):

```
Controllers/Api/       → HTTP endpoints (thin, delegate to Application layer)
Application/           → Query services + DTOs (CQRS read side)
Entities/              → Domain models (EF entities); base classes in Entities/Common/
Infrastructure/        → DbContext, DI registration, JWT, Serilog, CORS, health checks
Interfaces/            → Contracts (IContext, ICurrentUserService, ISpecification, etc.)
Specifications/        → Specification pattern (BaseSpecification + SpecificationEvaluator)
Enums/                 → Domain enumerations
Migrations/            → EF Core migrations
```

**Key patterns**:
- **Specification pattern** — `ISpecification<T>` + `SpecificationEvaluator` for composable queries; use `IReadOnlyContext` for reads
- **Auditing + soft delete** — All entities extend `BaseEntity<TId>` which implements `IAuditableEntity` and `IDeletableEntity`; global EF query filters exclude soft-deleted rows; auditing runs in `SaveChangesAsync`
- **Current user** — Injected via `ICurrentUserService`; reads JWT claims (sub, name, email, role)
- **DI registration** — Modular extension methods: `AddApplicationServices()`, `AddInfrastructureServices()`, `AddAuthentication()` called from `Program.cs`
- **DTOs** — API responses use records, never raw entities; see `Application/<Domain>/<Domain>Dto.cs`

## Configuration

**`appsettings.json`** (overridden by `appsettings.Development.json`):
- `ConnectionStrings:ApplicationContext` — PostgreSQL connection string
- `JwtSettings` — `Issuer`, `Audience`, `Key` (min 32 chars; use user secrets in dev)
- `Cors:AllowedOrigins` — Dev includes `http://localhost:3000`, `https://localhost:3001`, `http://localhost:5173`
- `Serilog` — structured console logging

Set the JWT key via user secrets in development:
```bash
dotnet user-secrets set "JwtSettings:Key" "<your-32+-char-key>"
```

## Entity Model

Core entities (all in `Entities/`): `User` (extends `IdentityUser`), `Wallet`, `Category`, `Transaction`, `Draft`, `Budget`, `BudgetAlert`, `SavingsGoal`, `Milestone`, `Subscription`, `Notification`.

See `guides/entities.md` for full field specifications and the ERD.

## Tech Stack

- **C# 13** with nullable enabled, implicit usings
- **ASP.NET Core 10.0** — controllers + middleware pipeline
- **EF Core 10.0** + **Npgsql** (PostgreSQL)
- **ASP.NET Core Identity** for user/role management
- **JWT Bearer** authentication (Issuer + Audience + key validation, zero clock skew)
- **Serilog** for structured logging
- **Swashbuckle** (Swagger/OpenAPI)
- **AspNetCore.HealthChecks.NpgSql** for DB health check
- **Newtonsoft.Json** (not System.Text.Json)
