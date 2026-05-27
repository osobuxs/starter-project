# Skill Registry — starter-project/frontend

**Generated**: 2026-04-15
**Stack**: Flutter/Dart, Clean Architecture, BLoC, Firebase

## User Skills

| Skill | Trigger | Source |
|-------|---------|--------|
| go-testing | Go tests, teatest, test coverage | ~/.claude/skills/go-testing |
| skill-creator | Create new skill, add agent instructions | ~/.claude/skills/skill-creator |
| judgment-day | Adversarial review, quality gate | ~/.claude/skills/judgment-day |
| branch-pr | Creating PR, opening PR | ~/.claude/skills/branch-pr |
| issue-creation | Creating GitHub issue, bug report, feature request | ~/.claude/skills/issue-creation |
| skill-registry | Update skills, skill registry | ~/.claude/skills/skill-registry |

## Project Conventions

| File | Purpose |
|------|---------|
| ~/.claude/CLAUDE.md | Global agent instructions, personality, SDD orchestrator config |

## Compact Rules

### branch-pr
- Follow issue-first enforcement: every PR must reference a GitHub issue
- Use conventional commit style for PR titles

### issue-creation
- Follow issue-first enforcement system
- Create issues before PRs

### judgment-day
- Launch two independent blind judge sub-agents in parallel
- Synthesize findings, apply fixes, re-judge until both pass or escalate after 2 iterations

## Stack-Specific Notes

- **Flutter/Dart** project with Clean Architecture (features-based structure)
- **State management**: flutter_bloc (BLoC/Cubit pattern)
- **DI**: get_it service locator
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Testing**: flutter_test + mockito + bloc_test
- **Linting**: flutter_lints
- **Architecture**: Domain-driven, feature-based modules (auth, articles, daily_news, user_profile)
