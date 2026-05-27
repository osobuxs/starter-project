# Skill Registry — starter-project

**Generated**: 2026-04-17  
**Stack**: Flutter/Dart, Clean Architecture, BLoC, Firebase

---

## User Skills

| Skill | Trigger | Purpose |
|-------|---------|---------|
| go-testing | Go tests, teatest, Bubbletea TUI testing | Go testing patterns |
| skill-creator | Create new skill, add agent instructions | Skill authoring |
| branch-pr | Creating pull request, PR workflow | PR creation automation |
| issue-creation | Creating GitHub issue, bug reports | Issue creation automation |

---

## SDD Skills (Auto-available)

| Skill | Trigger | Purpose |
|-------|---------|---------|
| sdd-init | SDD initialization | Bootstrap project context |
| sdd-explore | Codebase exploration | Investigation phase |
| sdd-propose | Change proposal | Proposal phase |
| sdd-spec | Specification writing | Spec phase |
| sdd-design | Technical design | Design phase |
| sdd-tasks | Task breakdown | Task breakdown phase |
| sdd-apply | Implementation | Apply/implementation phase |
| sdd-verify | Validation | Verification phase |
| sdd-archive | Archive completion | Archive/close phase |
| sdd-onboard | Guided walkthrough | Full SDD cycle walkthrough |

---

## Project Conventions

### Configuration Files
- **CLAUDE.md** (global): User's personal instructions for all projects
  - Personality: Senior Architect (15+ years), GDE/MVP
  - Language: Rioplatense Spanish (voseo) / English with warm tone
  - Rules: No "Co-Authored-By", no build after changes, use bat/rg/fd/sd/eza instead of cat/grep/find
  - Philosophy: CONCEPTS > CODE, foundations first, no shortcuts

### Architecture Patterns
- **Clean Architecture**: domain/data/presentation layers
- **DDD Principles**: Entities, Value Objects, Use Cases
- **Repository Pattern**: Abstract interfaces, implementation separation
- **BLoC Pattern**: State management with flutter_bloc
- **DI**: GetIt service locator with per-feature registration

### Testing Conventions
- **Unit Tests**: flutter_test + mockito
- **State Tests**: blocTest for BLoC transitions
- **Mock Generation**: mockito with build_runner
- **Test Structure**: Arrange-Act-Assert pattern
- **Coverage Target**: 80%+ for critical domain logic

### Code Style
- **Linter**: flutter_lints
- **Formatter**: dart format
- **Analyzer**: Dart built-in type checker

---

## Compact Rules (Auto-resolved for SDD phases)

### Flutter/Dart Implementation
When writing Flutter/Dart code:
1. Follow Clean Architecture (domain → data → presentation)
2. Use BLoC for state management, flutter_hooks for optimizations
3. Test all domain logic (use cases) with mockito mocks
4. Use blocTest for BLoC state transitions
5. Keep presentation layer UI-focused (no business logic)
6. Follow flutter_lints conventions strictly

### Testing in Flutter/Dart
1. Write tests alongside implementation (TDD strict mode)
2. Mock external dependencies (repositories, data sources)
3. Use mockito for generating mocks + bloc_test for BLoC tests
4. Test external behavior, not implementation details
5. One assertion per test when possible
6. Coverage target: 80%+ for domain logic

### Code Review / PR Standards
1. All changes must have passing tests
2. No "Co-Authored-By" attribution (conventional commits only)
3. Use semantic versioning (pubspec.yaml versioning)
4. Include rationale in commit messages (why, not just what)

---

## Next Steps

To update this registry with full details, run: `/skill-registry`
