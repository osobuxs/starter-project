# Skill Registry — starter-project

Generated: 2026-04-09

## User Skills (`~/.claude/skills/`)

| Skill | Trigger Context |
|-------|----------------|
| sdd-init | SDD initialization |
| sdd-explore | Explore/investigate ideas before a change |
| sdd-propose | Create change proposal |
| sdd-spec | Write specs with Given/When/Then |
| sdd-design | Architecture design document |
| sdd-tasks | Task breakdown checklist |
| sdd-apply | Implement tasks from a change |
| sdd-verify | Validate implementation against specs |
| sdd-archive | Archive a completed change |
| sdd-onboard | Guided SDD walkthrough |
| judgment-day | Adversarial parallel review |
| branch-pr | PR creation workflow |
| issue-creation | GitHub issue creation |
| skill-creator | Create new AI skills |
| skill-registry | Update skill registry |
| go-testing | Go test patterns (not applicable — Flutter project) |

## Project Conventions

No project-level CLAUDE.md detected. Global conventions apply from `~/.claude/CLAUDE.md`.

## Compact Rules (Flutter / Clean Architecture)

- Domain layer: pure Dart only — NO Flutter/Firebase imports
- Data sources: ONLY place to import Firebase/Dio/Floor
- Models: MUST extend entity, MUST have `fromRawData` factory and `toEntity()` method
- Repository impls: return `DataState<EntityType>` (never ModelType)
- Blocs/Cubits: ONLY place to call use cases
- Screens/Widgets: NO business logic, NO direct data layer access
- Boy Scout Rule: fix violations found in starter before adding new code
